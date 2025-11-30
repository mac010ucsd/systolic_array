wfname = "weight_itile0_otile0_kij0.txt"
wfname1 = "weight_itile0_otile0_kij1.txt"
afname = "activation_tile0.txt"

with open(wfname, "r") as f:
    wf = f.read()

with open(wfname1, "r") as f:
    wf1 = f.read()
    
with open(afname, "r") as f:
    af = f.read()

wf = wf.strip().split("\n")[3:]
wf1 = wf1.strip().split("\n")[3:]
af = af.strip().split("\n")[3:] 

wrd = 4

# print(wf)

w = [
    [(int(j, 2) - 2**4) 
     if ((j := row[i : i+4])[0] == '1')
     else int(j, 2) 
     for i in range(0, len(row), 4)] for row in wf]

w1 = [
    [(int(j, 2) - 2**4) 
     if ((j := row[i : i+4])[0] == '1')
     else int(j, 2) 
     for i in range(0, len(row), 4)] for row in wf1]
# print(w)

a = [
    [int(j, 2)
     if ((j := row[i : i+4])[0] == '1')
     else int(j,2) 
     for i in range(0, len(row), 4)] for row in af]

import numpy as np

w = np.array(w)
a = np.array(a)
w1 = np.array(w1)

print(w.T[::-1])
print(a[:, ::-1])

w = w.T[::-1]
w1 = w1.T[::-1]

a = a[:, ::-1]
print("psum0 \n", np.matmul(a, w))
print("psum1\n", np.matmul(a, w1))
print("psum0 + psum1 \n", np.matmul(a, w) + np.matmul(a, w1))
print(a.shape, w.shape)