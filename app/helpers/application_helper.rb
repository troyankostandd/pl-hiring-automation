module ApplicationHelper
  def checked_if(condition)
    condition ? 'checked' : nil
  end

  def selected_if(condition)
    condition ? 'selected' : nil
  end
end
