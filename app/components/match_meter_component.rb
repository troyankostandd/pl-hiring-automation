class MatchMeterComponent < ViewComponent::Base
  def initialize(matched, total, label: nil)
    @matched = matched
    @total = total
    @label = label || "#{@matched} / #{@total}"
  end

  def render?
    @total > 0
  end

  def match_ratio
    @total.zero? ? 0 : (@matched.to_f / @total * 100).round
  end

  def segments
    @total
  end

  def matched_segments
    @matched
  end
end
