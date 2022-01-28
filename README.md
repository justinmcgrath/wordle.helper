# wordle.helper
[Wordle](https://www.powerlanguage.co.uk/wordle/) is a game like Master Mind but that uses words. 

This package has some functions for use with the game. Response from Wordle are encoded as text strings: "o" for green, "u" for yellow, and "x" for gray.
The "o" and "x" are meant to represent circling or crossing out the letter, and "u" is similar to half an "o", for partially correct.

Given a guess word, response and list of words, which will be called a dictionary here, you can get the remaining possible words.
```r
possible_words(list('guess'), c('ooxux'), wordle_solution_dict)
```

Given a list of acceptable guess words and a list of possible target words, you can get a list of guess words sorted by how many target words they eliminate on average.
```r
# This will take a long time to run. The top word is "raise".
# Later this will be saved with the package for reference.
options = best_options(wordle_solution_dict, wordle_solution_dict)
```

The best first guess according that metric is "raise". After you make guesses you can determine the next best guesses.
```r
narrowed_list = possible_words(list('raise'), c('xxoxx'), wordle_solution_dict)
# When the list is narrowed, these run much more quickly.
hard_options = best_options(narrowed_list, narrowed_list)  # "Hard mode": Only guesses that incorporation known information are allowed.
easy_options = best_options(wordle_solution_dict, narrowed_list)  # "Hard mode": Only guesses that incorporation known information are allowed.

With more guesses, you can narrow further.
```r
narrowed_list = possible_words(list('raise', 'cling'), c('xxoxx', 'oxoxx'), wordle_solution_dict)
```

You can see what a result would be, which is probably only useful for writing other functions.
```r
wordle_result('chick', 'raise')
```

The game accepts about 13,000 words when guessing. However, there are only about 2,000 words that will be used as an answer. Thus two dictionaries are included in the package: `wordle_complete_dict` and `wordle_solution_dict`.
