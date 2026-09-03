# anyur (Rails) から anyur_cf (D1) へ移すデータを seed.sql に書き出す。
# 本番の Rails コンテナで実行する:
#
#   docker compose -f compose.exa.yaml exec -T -e RAILS_ENV=production app \
#     bin/rails runner script/export_seed.rb
#
# 出力は コンテナ内 /app/tmp/seed.sql (= ホストの src/tmp/seed.sql)。
# 手元に持ってきて投入する:
#
#   npx wrangler d1 execute anyur --remote --file=seed.sql
#
# 変換規則と投入手順は anyur_cf の docs/migration.md、
# 投入先のスキーマは anyur_cf の migrations/0001_init.sql。

out_path = ENV.fetch("SEED_PATH", Rails.root.join("tmp/seed.sql").to_s)

def sql(value)
  return "NULL" if value.nil?

  "'#{value.to_s.gsub("'", "''")}'"
end

notes = []
lines = [ "-- anyur -> D1 seed (#{Time.current.iso8601})" ]

# accounts ---------------------------------------------------------------
accounts = Account.isnt_deleted.order(:id).to_a

# 旧 password_digest は NULL 可、新 password_hash は NOT NULL。
# 空文字は verifyPassword が必ず false を返すので、パスワード再設定へ誘導することになる
no_password = accounts.count { |a| a.password_digest.blank? }
notes << "パスワード未設定 #{no_password} 件 (password_hash は '' で入る)" if no_password.positive?

# 新スキーマは COLLATE NOCASE UNIQUE。旧の CI インデックスより緩いことはないが念のため見る
[ [ :name_id, accounts.map(&:name_id) ], [ :email, accounts.filter_map(&:email) ] ].each do |column, values|
  dups = values.group_by { |v| v.to_s.downcase }.select { |_, g| g.size > 1 }.keys
  notes << "!! #{column} が大文字小文字違いで重複: #{dups.join(', ')}" if dups.any?
end

lines << ""
lines << "-- accounts (#{accounts.size})"
accounts.each do |a|
  values = [
    sql(a.aid),
    sql(a.name),
    sql(a.name_id),
    sql(a.description.to_s),
    sql(a.birthdate&.strftime("%Y-%m-%d")),
    sql(a.email.presence),
    a.email_verified ? 1 : 0,
    sql(a.password_digest.to_s),
    sql(a.status),
    a.created_at.to_i,
    a.updated_at.to_i
  ]
  lines << "INSERT INTO accounts (id, name, name_id, description, birthdate, email, " \
           "email_verified, password_hash, status, created_at, updated_at) " \
           "VALUES (#{values.join(', ')});"
end

# grants -----------------------------------------------------------------
# persona_id は連携先 DB の外部キーなので必ず維持する
alive = accounts.map(&:id).to_set
skipped = Hash.new(0)
grants = {}

Persona.is_normal.includes(:account, :service).order(:created_at).each do |p|
  account = p.account
  service = p.service
  next skipped[:アカウントが削除済み] += 1 unless account && alive.include?(account.id)
  next skipped[:サービスが削除済み] += 1 unless service && !service.deleted?

  # 新スキーマの UNIQUE (account_id, service_id)。重複したら新しい方を残す
  key = [ account.aid, service.name_id ]
  skipped[:同じサービスの重複] += 1 if grants.key?(key)
  grants[key] = [ p, account, service ]
end

lines << ""
lines << "-- grants (#{grants.size})"
grants.each_value do |(persona, account, service)|
  values = [
    sql(persona.aid),
    sql(account.aid),
    sql(service.name_id),
    sql(Array(persona.scopes).map(&:to_s).uniq.join(" ")), # 旧は JSON 配列、新はスペース区切り
    persona.created_at.to_i
  ]
  lines << "INSERT INTO grants (persona_id, account_id, service_id, scopes, created_at) " \
           "VALUES (#{values.join(', ')});"
end

File.write(out_path, "#{lines.join("\n")}\n")

puts "書き出し: #{out_path}"
puts "accounts: #{accounts.size} (locked #{accounts.count { |a| a.locked? }})"
puts "grants:   #{grants.size}"
grants.keys.group_by(&:last).sort_by { |_, g| -g.size }.each do |service_id, g|
  puts "  #{service_id}: #{g.size}"
end
skipped.each { |reason, count| puts "スキップ #{reason}: #{count}" }
notes.each { |n| puts n }
