import common

# Return the length of the longest common substring between 2 strings
def LCSubstr_len(S, T):
  m = len(S); n = len(T)
  L = [[0] * (n+1) for i in xrange(m+1)]
  lcs = 0
  for i in xrange(m):
    for j in xrange(n):
      if S[i] == T[j]:
        L[i+1][j+1] = L[i][j] + 1
        lcs = max(lcs, L[i+1][j+1])
      else:
        L[i+1][j+1] = max(L[i+1][j], L[i][j+1])
  return lcs
 
# Return the longest common substring between 2 strings
def LCSubstr_set(S, T):
  m = len(S); n = len(T)
  L = [[0] * (n+1) for i in xrange(m+1)]
  LCS = set()
  longest = 0
  for i in xrange(m):
    for j in xrange(n):
      if S[i] == T[j]:
        v = L[i][j] + 1
        L[i+1][j+1] = v
        if v > longest:
          longest = v
          LCS = set()
        if v == longest:
          LCS.add(S[i-v+1:i+1])
  return LCS


# exluding the track terms of the piece (defined in common)
def totalDistance(subStrSet):
  d = 0
  for sub in subStrSet:
    for term in common.track_terms:
      sub = sub.replace(term, "")
    if len(sub) >= common.triggerLengthThreshold:
      d += len(sub)
  return d