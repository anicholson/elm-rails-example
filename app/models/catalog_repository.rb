class CatalogRepository
  class << self
    include ActionView::Helpers::AssetUrlHelper
    def get
      @catalog ||= {
        catalog: {
          products:
            [
              {
                name: "Tulips",
                code: "T58",
                imageUrl: image_path("tulips.jpg"),
                description: "The tulip is a Eurasian and North African genus of herbaceous, perennial, bulbous plants in the lily family, with showy flowers. About 75 wild species are currently accepted.",

                prices: [
                  { amount: 3, price: 595},
                  { amount: 5, price: 995},
                  { amount: 9, price: 1699}
                ]
              },
              {
                name: "Roses",
                code: "R12",
                imageUrl: image_path("roses.jpg"),
                description: "A rose is a woody perennial flowering plant of the genus Rosa, in the family Rosaceae, or the flower it bears. There are over a hundred species and thousands of cultivars. They form a group of plants that can be erect shrubs, climbing or trailing with stems that are often armed with sharp prickles. Flowers vary in size and shape and are usually large and showy, in colours ranging from white through yellows and reds.",

                prices: [
                  { amount: 5, price: 699 },
                  { amount: 10, price: 1299 }
                ]
              },
              {
                name: "Lilies",
                code: "L09",
                imageUrl: image_path("lilies.jpg"),
                description: %q{Lilium (members of which are true lilies) is a genus of herbaceous flowering plants growing from bulbs, all with large prominent flowers. Lilies are a group of flowering plants which are important in culture and literature in much of the world. Most species are native to the temperate northern hemisphere, though their range extends into the northern subtropics. Many other plants have "lily" in their common name but are not related to true lilies.},
                prices: [
                  { amount: 3, price: 995 },
                  { amount: 6, price: 1695},
                  { amount: 9, price: 2495}
                ]
              }
            ]
        }
      }.freeze
    end
  end
end
