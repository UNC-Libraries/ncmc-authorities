
## Names

### Types

6/6/19: {"corporate"=>13266, "personal"=>107797, "family"=>632,
         "unknown"=>6477, "meeting"=>79, "person"=>379}

- ("person" should be rolled into "personal")
- we currently only trying to match names of the same type; for a personal name we only try to find matches with other personal names
- at some point we'll have to do something with unknown-type names
- some names are obviously miscategorized, but a legitimate stance could be that those mistakes should be cleaned up in the underlying data and not something we need to mitigate or account for
- I'm unsure of whether there is any large scale miscategorization; for example if some institution or collection used "personal" in place of "family" name for every family name
- There are few enough meeting/family names that they seem low priority. I'd guess we'll be able to treat meeting names like we do corporate names, and do something quick/simple for family names and think that's good enough for now.

## Matching

At the moment, nothing we're doing looks at non-name data to find matches. At some point we could include matching on lcnaf strings/urls. We don't do anything with data in the variants (variant names) field of the incoming data.

At the moment we try to categorize matches as strong, moderate, weak or bad, where strong and moderate should be interesting, and weak matches should be not very interesting. The number/percentile of names with strong matches is, I imagine, what we'll report as the % overlap.

### Personal

We parse names as:
	Surnames, Forenames (Variant), supplemental_data
	Smith, P. (Pat), vocalist
and take any sequences of 3/4 digits anywhere as dates. This is not perfect but seems mostly tolerable.

We cluster personal names by Soundex of their surname or surname components.
	- "Smith-Brown, Pat" is clustered as both ```soundex(Smith)``` and ```soundex(Brown)```

Then, for a name, we only check for matches with other members of its cluster(s).

At the moment we generate a composite similarity score based on weightings of:

- levenshtein similarity between surname
- levenshtein similarity between forename
- trigram similarity between supplemental_data
- a custom thing between forename - this is mainly to account for initials being reasonably okay matches for names that begin with that letter. Which doesn't generally get accounted for with edit distance algorithms. (e.g. we want "Smith, Robert" to be a better match with "Smith, R" than with "Smith, Hubert")

Notes:
- We don't yet do anything with dates
- We don't yet do anything special with variant/clarifying names
- Anything mononymic (Aristotle) or not in inverted "LastName, Forenames" form (Pat Brown) isn't parsed well; approx everything is treated as a surname. At some point we should see how many of these there are and how their matching is doing.

### Corporate

We take the normalized name and break it into trigrams (letter-level). A name is in a cluster for each of the first trigrams of each word. So:
	name: American Home Foods
	trigrams: ["ame", "mer", "eri", "ric", "ica", "can", "ame!", "ame!", "a#", "hom", "ome", "hom!", "hom!", "h#", "foo", "ood", "ods", "foo!", "foo!", "f#"]
	clusters: ["ame", "hom", "foo"]

Then, for a name, we only check for matches with other members of its cluster(s).

At the moment we generate a "composite" similarity score based on:
 - trigram similarity weighted by term frequency-inverse document frequency (so trigrams that are common in the corpus count less than rare trigrams)


