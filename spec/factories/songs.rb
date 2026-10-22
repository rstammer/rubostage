FactoryBot.define do
  factory :song do
    request { "Starlight von Muse" }

    trait :manual do
      origin { "manual" }
      request { nil }
    end

    trait :ready do
      title { "Starlight" }
      artist { "Muse" }
      key { "B" }
      bpm { 122 }
      status { "ready" }
      sheet do
        {
          "title" => "Starlight", "artist" => "Muse", "key" => "B", "bpm" => 122,
          "sections" => [{"name" => "Verse", "bars" => [["B"], ["C#m"], ["G#m"], ["E"]]}],
          "form" => ["Verse"]
        }
      end
      code { "use_bpm 122\nplay 60" }
    end
  end
end
