wordle_result = function(target, guess) {
    targ = strsplit(target, '')[[1]]
    gues = strsplit(guess, '')[[1]]
    # If a word contains a letter multiple times, the result isn't simply
    # "matched", "out of place", or "not in word". If it's in the right place,
    # that's always marked. Otherwise, letters are marked as "out of place"
    # from left to right in the guess, until the letter has been marked as
    # "matched" or "out of place" as many times as it occurs in the word. Then
    # further guesses are marked "not in word".

    # First mark all the "matched" letters and store them.
    result = character(length(targ))
    correct_letters = character()
    for (i in seq_along(targ)) {
        if (targ[i] == gues[i]) {
            result[i] = 'o'
            correct_letters = append(correct_letters, gues[i])
        }
    }

    # Mark "out of place" guesses from left to right accounting for multiple
    # occurances.  of a single letter.
    # Maybe rearrange this logic so that you start with 'xxxxx', and you don't
    # need the else branch.
    for (i in which(result != 'o')) {
        if (!(gues[i] %in% targ) || (sum(correct_letters == gues[i]) >= sum(targ == gues[i]))) {  # The letter isn't in the word, or the letter is in the word, but has been marked correct the proper number of times.
            result[i] = 'x'
        } else {
            result[i] = 'u'
            correct_letters = append(correct_letters, gues[i])
        }
    }
    return(result)
}

regex_from_result = function(guess_list, result_list) {
    word_chars = nchar(guess_list[[1]])
    known = character(word_chars)
    not_in_place = vector('list', word_chars)
    not_present = character()
    n_present = list()
    for (row in seq_along(guess_list)) {
        result = result_list[[row]]
        guess_word = strsplit(guess_list[[row]], '')[[1]]

        for (i in seq_along(guess_word)) {
            guess_letter = guess_word[i]
            result_code = result[i]
            if (result_code == 'x') {
                match_inds = guess_letter == guess_word
                n_in_word = sum(match_inds)
                if (n_in_word == 1) {  # If a letter is present in the target word, but occurs more times in the guess than in the target, some guess letters are marked 'x'.
                    not_present = append(not_present, guess_letter)
                } else {
                    n_present[[guess_letter]] = length(which(result[match_inds] %in% c('o', 'u')))
                }
            } else if (result_code == 'u') {
                not_in_place[[i]] = c(not_in_place[[i]], guess_letter)
            } else if (result_code == 'o') {
                known[i] = guess_letter
            }
        }

    }

    not_present = unique(not_present)

    #ul = function(x) {  # Returns the unique set of letters in the word `x`.
        #x = paste0(x, collapse='')
        #unique(strsplit(x, '')[[1]])
    #}

    for (i in seq_along(not_in_place)) {
        unique_letters = paste0(unique(not_in_place[[i]]), collapse='')
        if (length(unique_letters) > 0) {
            not_in_place[[i]] = unique_letters
        }
    }
    not_in_place = as.character(not_in_place)

    regex_pattern = known
    n_not_present = length(not_present)
    np_pattern = sprintf('[^%s]', paste0(not_present, collapse=''))
    for (i in which(known == '')) {
        not_here = not_in_place[i]
        if (n_not_present > 0) {
            if (not_here == '') {
                regex_pattern[i] = np_pattern
            } else {
                regex_pattern[i] = sprintf('[^%s]', paste0(c(not_present, not_here), collapse=''))
            }
        } else {
            regex_pattern[i] = '.'
        }
    }

    not_present_regex = character()
    for (i in seq_along(n_present)) {
        l = names(n_present)[i]
        pattern = sprintf('[^%s]*%s', l, l)
        pattern = paste0(rep(pattern, n_present[[i]]), collapse='')
        pattern = sprintf('%s[^%s]*', pattern, l)
        pattern = sprintf("(?=^%s$)", pattern)
        not_present_regex = paste0(not_present_regex, pattern, collapse='')
    }

    not_in_place = paste0('(?=.*?', not_in_place, ')', collapse='')
    #regex_pattern = paste0(regex_pattern, collapse='')
    paste0(c(not_present_regex, not_in_place, regex_pattern), collapse='')
}

remaining = function(target, guess, words) {
    r = wordle_result(target, guess)
    regex_list = regex_from_result(list(guess), list(r))
    grep(regex_list, words, value=TRUE, perl=TRUE)
}

system_grep = function(regex, to_search, ...) {
    word_list = paste0(to_search, '\n', collapse='')
    arg_list = sprintf('-c \'grep -P "%s" <(echo -e "%s")\'', regex, word_list)
    system2("bash", arg_list, stdout=TRUE)
}

grep_and = function(regex_list, x, ...) {
    r = x
    for (i in seq_along(regex_list)) {
        r = grep(regex_list[i], r, ...)
    }
    r
}

one_row = function(guess, target_words) {
        n_remaining = integer(length(target_words))
        for (t in seq_along(target_words)) {
            target = target_words[t]
            n_remaining[t] = length(remaining(target, guess, target_words))
        }
        n_remaining
}

possible_words = function(guesses, responses, dict) {
    regex = regex_from_result(guesses, strsplit(responses, ''))
    grep(regex, dict, value=TRUE, perl=TRUE)

}

# It seems that using <<- within a function to set package-wide variables does not work.
# Create this function in a local environment to keep those variables with the function.
best_options = local({
    no_cores <- detectCores()
    # If pbapply is available, use that to get a progress bar.
    has_pbapply = suppressWarnings(suppressPackageStartupMessages(require(pbapply)))

    apply_func = if (has_pbapply) {
        show_pbapply_msg = FALSE
        function(cl, X, fun, target_words) pbapply::pblapply(cl=cl, X=X, FUN=fun, target_words=target_words)
    } else {
        show_pbapply_msg = TRUE
        parLapply
    }
    function(guess_words, target_words) {
        if (show_pbapply_msg) {
            show_pbapply_msg <<- FALSE
            warning("If you install `pbapply`, `best_options` will show a progress bar.")
        }

        cl <- makeForkCluster(no_cores)
        on.exit(stopCluster(cl))
        clusterExport(cl, c("remaining", 'wordle_result', 'regex_from_result'))
        r = apply_func(cl=cl, X=guess_words, fun=one_row, target_words=target_words)
        r = do.call(rbind, r)

        means = apply(r, 1, mean)
        both = data.frame(words=guess_words, mean=means)
        both = both[order(both$mean), ]
        rownames(both) = NULL
        both
    }
})

