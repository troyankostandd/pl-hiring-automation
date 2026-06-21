class IngredientNormalizer
  PANTRY_STAPLES = [
    "salt", "black pepper", "pepper", "water", "oil", "olive oil",
    "vegetable oil", "butter", "sugar", "all-purpose flour", "flour"
  ].freeze

  # Descriptors are stripped as whole words only.
  DESCRIPTORS = %w[
    fresh dried ground chopped finely coarsely minced diced sliced peeled
    shredded grated crushed cooked uncooked frozen melted softened beaten
    large medium small ripe organic optional divided freshly thinly thickly
    boneless skinless lean whole halved quartered cubed packed sifted warm cold
    hot cut into pieces room temperature plus more for serving to taste
    such as or your favorite about
  ].freeze

  # Measurement words and abbreviations, stripped as whole words (with optional
  # trailing "s"). Order longest-first so e.g. "fluid ounce" is removed before "ounce".
  UNITS = [
    "fluid ounce", "fluid oz",
    "tablespoon", "teaspoon", "tbsp", "tbs", "tsp",
    "ounce", "pound", "gram", "kilogram", "milliliter", "liter", "litre",
    "cup", "pint", "quart", "gallon", "package", "pkg", "container", "jar",
    "can", "bottle", "box", "bag", "stick", "clove", "bunch", "sprig",
    "slice", "head", "stalk", "pinch", "dash", "handful", "piece",
    "oz", "lb", "lbs", "kg", "ml", "g", "l"
  ].freeze

  UNICODE_FRACTIONS = {
    "¼" => 0.25, "½" => 0.5, "¾" => 0.75, "⅓" => 1.0 / 3, "⅔" => 2.0 / 3,
    "⅕" => 0.2, "⅖" => 0.4, "⅗" => 0.6, "⅘" => 0.8, "⅙" => 1.0 / 6,
    "⅚" => 5.0 / 6, "⅛" => 0.125, "⅜" => 0.375, "⅝" => 0.625, "⅞" => 0.875
  }.freeze

  def self.call(original_text)
    new(original_text).call
  end

  def initialize(original_text)
    @original_text = original_text.to_s
    @text = @original_text.downcase.strip
  end

  def call
    name = parse_ingredient
    {
      original_text: @original_text,
      quantity: parse_quantity,
      unit: parse_unit,
      ingredient_name: name,
      is_pantry_staple: pantry_staple?(name)
    }
  end

  private

  def parse_quantity
    # Unicode fraction (optionally with a leading whole number, e.g. "1 ½").
    if (m = @text.match(/(\d+)?\s*([#{UNICODE_FRACTIONS.keys.join}])/))
      return (m[1].to_i + UNICODE_FRACTIONS[m[2]]).round(3)
    end
    # ASCII fraction "1/2" or "1 1/2".
    if (m = @text.match(/(\d+)\s+(\d+)\s*\/\s*(\d+)/))
      return (m[1].to_i + m[2].to_f / m[3].to_i).round(3)
    end
    if (m = @text.match(/(\d+)\s*\/\s*(\d+)/))
      return (m[1].to_f / m[2].to_i).round(3)
    end
    if (m = @text.match(/\d+(?:\.\d+)?/))
      return m[0].to_f
    end
    nil
  end

  def parse_unit
    cleaned = strip_quantities(@text)
    UNITS.find { |unit| cleaned.match?(/\b#{Regexp.escape(unit)}s?\b/) }
  end

  def parse_ingredient
    cleaned = @text.dup
    cleaned = cleaned.gsub(/\([^)]*\)/, " ")            # parenthetical notes
    cleaned = strip_quantities(cleaned)
    UNITS.each { |u| cleaned.gsub!(/\b#{Regexp.escape(u)}s?\b/, " ") }
    DESCRIPTORS.each { |d| cleaned.gsub!(/\b#{Regexp.escape(d)}\b/, " ") }
    cleaned = cleaned.split(/[,;]/).first.to_s        # drop trailing notes after a comma
    cleaned = cleaned.gsub(/[^a-z\s-]/, " ")           # keep letters, spaces, hyphens
    cleaned = cleaned.gsub(/\b(of|the|a|an|and|or|for|with|into)\b/, " ")
    cleaned = cleaned.gsub(/\s+/, " ").strip.gsub(/\A-+|-+\z/, "").strip
    cleaned.split.map { |w| w.singularize }.join(" ")
  end

  def strip_quantities(str)
    str.gsub(/[#{UNICODE_FRACTIONS.keys.join}]/, " ")
       .gsub(/\d+\s*\/\s*\d+/, " ")
       .gsub(/\d+(?:\.\d+)?/, " ")
  end

  def pantry_staple?(name)
    return false if name.blank?
    PANTRY_STAPLES.any? { |staple| name == staple || name.include?(staple) }
  end
end
