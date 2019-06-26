
## Names

### Types

{"corporate"=>13266, "personal"=>108176, "family"=>632,
 "unknown"=>6477, "meeting"=>79}
- some names are obviously miscategorized, but a legitimate stance could be that those mistakes should be cleaned up in the underlying data and not something we need to mitigate or account for

## Matching

At the moment we try to categorize matches as strong, moderate, weak or bad, where strong and moderate should be interesting, and weak matches should be not very interesting. The number/percentile of names with strong matches is, I imagine, what we'll report as the % overlap.

### Personal

We parse names as:
	Surnames, Forenames (Variant), supplemental_data
	Smith, P. (Pat), vocalist
and take any sequences of 3/4 digits anywhere as dates. This is not perfect but seems mostly tolerable.

We block personal names by Soundex of their surname or surname components.
	- "Smith-Brown, Pat" is blocked as both ```soundex(Smith)``` and ```soundex(Brown)```

Then, for a name, we only check for matches with other members of its block(s).

At the moment we generate a composite similarity score based on weightings of:

- levenshtein similarity between surname
- levenshtein similarity between forename
- trigram similarity between supplemental_data
- a custom thing between forename - this is mainly to account for initials being reasonably okay matches for names that begin with that letter. Which doesn't generally get accounted for with edit distance algorithms. (e.g. we want "Smith, Robert" to be a better match with "Smith, R" than with "Smith, Hubert")
- the score is rewarded when names contain matching dates and penalized when containing dates that don't match

Notes:
- We don't yet do anything special with variant/clarifying names - (n=3585)
- Anything mononymic (Aristotle) or not in inverted "LastName, Forenames" form (Pat Brown) isn't parsed well; approx everything is treated as a surname.
  - There are less than 430 of these. A good half or more of those look to be corporate names or family names. There are also somenumber of username type names (e.g. mtsmith2). So maybe 100-200 legit mononyms / non-inverted names/ (non-inverted) initials.

### Corporate

We take the normalized name and break it into trigrams (letter-level). A name is in a block for each of the first trigrams of each word. So:
	name: American Home Foods
	trigrams: ["ame", "mer", "eri", "ric", "ica", "can", "ame!", "ame!", "a#", "hom", "ome", "hom!", "hom!", "h#", "foo", "ood", "ods", "foo!", "foo!", "f#", "a h", "h f"]

At the moment we generate a "composite" similarity score based on:
 - trigram similarity weighted by term frequency-inverse document frequency (so trigrams that are common in the corpus count less than rare trigrams)

This is done using default lucene scoring, which might include factors such as document length in the score. The scores lucene yields are normalized based on the lucene score of the original document which is an exact match.

### Family

Normalize names (including removal of: "family", "of", "the")

Blocked by soundex of any name token:
		- "Smith-Brown Family" is blocked as both ```soundex(Smith)``` and ```soundex(Brown)```

Then, for a name, we only check for matches with other members of its block(s), using only
levenshtein similarity.

### Meeting

Handled in the same way as corporate names. (This not meant to imply that meeting names are also blocked or compared with corporate names.)

### Unknown

Names with unknown type are blocked with and compared against names of each of the other, determinate, types. This also means that names of the determinate types are also compared against unknown-type names (along with names of their own type).

When comparing an unknown-type name against an unknown-type name, they end up being compared
as each of the types: personal names, corporate names, etc.; we take the best of those comparisons.

### Generally applicable notes on matching

Names of all types are given a large boost if they have matching lcnaf strings (via basic normalization) or uri's (by parsing out an lc name id).

Ideally we'd also be taking names and matching them (incl., if any, their variant name(s) or lcnaf string) against the pool of all names, variant names, lcnaf strings. (where, currently, we compare
names only with names, lcnaf strings only with lcnaf strings, do nothing with variant names, and do nothing between those groups.)
- but there are only 13 names with a populated variants field
- and there are only 1353 names with populated lcnaf string of which only 325 have names that do not exactly match the lcnaf string (of which only 224 don't match after basic normalization)

