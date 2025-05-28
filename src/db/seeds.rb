# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Account.create!(
  id: "00000000000000",
  name: "kisana",
  name_id: "kisana",
  email: "kisana@kisana.me",
  email_verified: true,
  roles: "admin",
  password: "kisana528",
  password_confirmation: "kisana528"
)
Service.create!(
  name: "Amiverse",
  name_id: "Amiverse",
  summary: "Amiverse SNS",
  description: "![アイコン](https://kisana.me/images/amiverse/amiverse-1.png)\n## Amiverse 新しいSNS\nリアクションをつけたり、フェディバースに繋がったり、たくさんの機能があります。",
  host: "amiverse.net"
)
Service.create!(
  name: "IVECOLOR",
  name_id: "IVECOLOR",
  summary: "IVECOLOR BLOG",
  description: "![アイコン](https://kisana.me/images/ivecolor/ivecolor-1.png)\n## IVECOLORで記事を読もう\n沢山の魅力的な記事があります。最新情報を発信中！",
  host: "ivecolor.com"
)
Service.create!(
  name: "KISANA:ME",
  name_id: "KISANA_ME",
  summary: "KISANA:ME プロフィール",
  description: "![アイコン](https://kisana.me/images/kisana/kisana-1.png)\n## KISANA:ME どんな人？\nkisanaのプロフィール情報があります。",
  host: "kisana.me"
)
Service.create!(
  name: "Be Alive.",
  name_id: "Be_Alive",
  summary: "Be Alive. 生存確認",
  description: "![アイコン](https://kisana.me/images/bealive/bealive-1.png)\n## Be Alive. 生存確認しあおう\n任意の相手にURLを送りつけて写真を撮ってもらおう！",
  host: "bealive.amiverse.net"
)
Service.create!(
  name: "得句巣",
  name_id: "x_ekusu",
  summary: "得句巣 英字漢字",
  description: "![アイコン](https://kisana.me/images/x/x-1.png)\n## 得句巣 独英字漢字世界\nエクスでは英字と漢字しか使えません！新たなコミュニケーション形態のSNSです！",
  host: "x.amiverse.net"
)