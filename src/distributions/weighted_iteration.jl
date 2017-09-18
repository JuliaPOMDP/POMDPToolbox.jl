"""
    weighted_iterator(d)

Return an iterator through pairs of the values and probabilities in distribution `d`.

This is designed to speed up value iteration. Distributions are encouraged to provide a custom optimized implementation if possible.
"""
weighted_iterator(d) = (x=>pdf(d, x) for x in iterator(d))
