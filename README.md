# wordle.helper
[Wordle](https://www.powerlanguage.co.uk/wordle/) is a game like Master Mind except that it uses words. 

This package has some functions for use with the game. Responses from Wordle are encoded as text strings: "o" for green, "u" for yellow, and "x" for gray.
The "o" and "x" are meant to represent circling or crossing out the letter, and "u" is similar to half an "o", for partially correct.

The game accepts about 13,000 words when guessing. However, there are only about 2,000 words that will be used as an answer. Thus two dictionaries are included in the package: `wordle_complete_dict` and `wordle_solution_dict`.

Given a guess word, response, and list of words, you can get the remaining possible words.
```r
# Using the word "guess" the response was green, green, gray, yellow, gray.
possible_words(list('guess'), c('ooxux'), wordle_solution_dict)
```

Given a list of acceptable guess words and a list of possible target words, you can get a list of new guess words sorted by how many target words they eliminate on average.
```r
# This will take a long time to run. The top word is "raise".
# Later this will be saved with the package for reference.
options = best_options(wordle_solution_dict, wordle_solution_dict)
```

To create this list, for every target, every guess word is tried. The number of possible words remaining is determined for each guess-target pair. The average number of words remaining for a guess against all targets is determined. The reasoning is that there is equal probability that any of the remaining words could be the target word, and the best guess is the one that on average eliminates the most possible words.

The best first guess according that metric is "raise". After you make guesses you can determine the next best guesses. When the list is narrowed, these run much more quickly.
```r
narrowed_list = possible_words(list('raise'), c('xxoxx'), wordle_solution_dict)

# "Hard mode": Only guesses that incorporation known information are allowed.
hard_options = best_options(narrowed_list, narrowed_list)

# "Easy mode": Any acceptable word can by used as a guess.
easy_options = best_options(wordle_solution_dict, narrowed_list)
```

With more guesses, you can narrow further.
```r
narrowed_list = possible_words(list('raise', 'cling'), c('xxoxx', 'oxoxx'), wordle_solution_dict)
```

You can see what a result would be, which is probably only useful for writing other functions.
```r
wordle_result('chick', 'raise')
```

I'd like to change some details. It's odd that guesses are given as a list while responses are vectors. An even better change would be to encode the two together so that `possible_words` is used as follows.
```r
# This arrangment makes it easier to add new guess-response pairs.
possible_words(c('raise,xxoxx', 'cling,oxoxx'))
```
