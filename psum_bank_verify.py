wfname = "weight_itile0_otile0_kij0.txt"
afname = "activation_tile0.txt"

with open(wfname, "r") as f:
    wf = f.read()

    
with open(afname, "r") as f:
    af = f.read()

wf = wf.strip().split("\n")[3:]
af = af.strip().split("\n")[3:] 

wrd = 4

# print(wf)

w = [
    [(int(j, 2) - 2**4) 
     if ((j := row[i : i+4])[0] == '1')
     else int(j, 2) 
     for i in range(0, len(row), 4)] for row in wf]

# print(w)

a = [
    [int(j, 2)
     if ((j := row[i : i+4])[0] == '1')
     else int(j,2) 
     for i in range(0, len(row), 4)] for row in af]

import numpy as np

w = np.array(w)
a = np.array(a)
p = np.matmul(a, w)
#print(w)
#print(a)
print(w.T[::-1])
print(a[:, ::-1])
w = w.T[::-1]
a = a[:, ::-1]
print(np.matmul(a, w))
for i in range(1, len(w)+1):
    print(a[0, :i], w[:i,0], np.matmul(a[0, :i], w[:i, 0]))


print(a.shape, w.shape)