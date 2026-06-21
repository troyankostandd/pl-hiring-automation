class IngredientNormalizer
  PANTRY_STAPLES = %w[
    salt black pepper water oil olive oil butter sugar all-purpose flour
  ].freeze

  DESCRIPTORS = %w[
    fresh dried ground chopped finely coarsely minced diced sliced peeled
    large medium small ripe organic optional divided to taste freshly plus more for serving
  ].freeze

  UNITS = %w[
    cup tbsp tsp g kg oz lb ml l pinch dash clove bunch can slice sprig
  ].freeze

  def self.call(original_text)
    new(original_text).call
  end

  def initialize(original_text)
    @original_text = original_text
    @text = original_text.downcase.strip
  end

  def call
    {
      original_text: @original_text,
      quantity: parse_quantity,
      unit: parse_unit,
      ingredient_name: parse_ingredient,
      is_pantry_staple: check_pantry_staple
    }
  end

  private

  def parse_quantity
    # Very simplified quantity parsing
    if @text.match?(/(\d+)(\s+)?\/(\s+)?(\d+)/)
      match = @text.match(/(\d+)(\s+)?\/(\s+)?(\d+)/)
      numerator = match[1].to_i
      denominator = match[4].to_i
      numerator.to_f / denominator
    elsif @text.match?(/\d+/)
      @text.match(/\d+/)[0].to_i
    end
  end

  def parse_unit
    UNITS.find { |unit| @text.include?(unit) }
  end

  def parse_ingredient
    # Remove quantity, unit, and descriptors
    cleaned = @text.dup
    cleaned.gsub!(/\d+\s*\/\s*\d+/, "")
    cleaned.gsub!(/\d+/, "")
    UNITS.each { |unit| cleaned.gsub!(/#{unit}s?/, "") }
    DESCRIPTORS.each { |desc| cleaned.gsub!(/#{desc}/, "") }

    # Clean up and singularize
    cleaned.strip.gsub(/[,;].*/, "").strip.singularize.downcase
  end

  def check_pantry_staple
    ingredient_name = parse_ingredient
    PANTRY_STAPLES.any? { |staple| ingredient_name.include?(staple) }
  end
end
