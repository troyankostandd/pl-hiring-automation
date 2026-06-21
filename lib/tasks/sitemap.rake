namespace :sitemap do
  desc "Generate sitemap.xml"
  task generate: :environment do
    Sitemap.generate!
  end
end

class Sitemap
  def self.generate!
    recipes = Recipe.select(:slug, :updated_at)
    sitemap_xml = generate_xml(recipes)

    File.write(Rails.root.join("public/sitemap.xml"), sitemap_xml)
    puts "Sitemap generated: #{recipes.count} recipes"
  end

  def self.generate_xml(recipes)
    builder = Builder::XmlMarkup.new(indent: 2)

    builder.instruct! :xml, version: "1.0", encoding: "UTF-8"
    builder.urlset(xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9") do |urlset|
      # Static pages
      [
        { loc: Rails.application.routes.url_helpers.root_url, changefreq: "weekly", priority: 1.0 },
        { loc: Rails.application.routes.url_helpers.about_url, changefreq: "yearly", priority: 0.5 },
      ].each do |page|
        urlset.url do |url|
          url.loc page[:loc]
          url.lastmod Time.current.iso8601
          url.changefreq page[:changefreq]
          url.priority page[:priority]
        end
      end

      # Recipe pages
      recipes.each do |recipe|
        urlset.url do |url|
          url.loc Rails.application.routes.url_helpers.recipe_url(recipe.slug)
          url.lastmod recipe.updated_at.iso8601
          url.changefreq "monthly"
          url.priority 0.7
        end
      end
    end

    builder.target!
  end
end
