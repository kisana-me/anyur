module ApplicationHelper
  def full_title(t)
    return (t.blank? ? "" : t + " | ") + "ANYUR"
  end
end
