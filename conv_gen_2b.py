import torch
import torch.nn as nn
import numpy as np

# Set random seed for reproducibility
torch.manual_seed(42)

# Create the convolution layer
conv = nn.Conv2d(
    in_channels=16,     # 16 input channels
    out_channels=8,    # 8 output channels  
    kernel_size=3,     # 3x3 kernel
    padding=0,         # no padding
    bias=False          # no bias
)

# Print layer information
print(f"Conv layer: {conv}")
print(f"Weight shape: {conv.weight.shape}")  # [out_channels, in_channels, kernel_h, kernel_w]
conv.weight = nn.Parameter(torch.randint(-8, 8, (8, 16, 3, 3)), requires_grad=False)

# Create random input tensor: [batch_size, channels, height, width]
# Require 2-bit max (value=4)
input_tensor = torch.randint(4, (16, 6, 6))  # batch_size=1, 8 channels, 6x6 spatial
print(f"Input shape: {input_tensor.shape}")

# Perform convolution
output = conv(input_tensor)
print(f"Output shape: {output.shape}") 


# print(output)

X = torch.flatten(input_tensor, 1,2)

bit_precision = 2
file = open('activation2_tile0.txt', 'w') #write to file
file.write('#time0row15[msb-lsb],time0row6[msb-lst],....,time0row0[msb-lst]#\n')
file.write('#time1row15[msb-lsb],time1row6[msb-lst],....,time1row0[msb-lst]#\n')
file.write('#................#\n')

for i in range(X.size(1)):  # time step
    for j in range(X.size(0)): # row #
        X_bin = '{0:02b}'.format(round(X[15-j,i].item()))
        for k in range(bit_precision):
            file.write(X_bin[k])        
        #file.write(' ')  # for visibility with blank between words, you can use
    file.write('\n')
file.close() #close file    

# print(X)

z = lambda x: ("{0:04b}".format(x) if x >= 0 else "1{0:03b}".format(8+x))

W = torch.flatten(conv.weight, 2,3)
# W[:,:,0] = (torch.arange((8*8))%16 - 8).reshape(8,8)

# W = w_tile[tile_id,:,:,kij]  # w_tile[tile_num, array col num, array row num, kij]

bit_precision = 4

for kij in range(9):
    file = open(f'weight2_itile0_otile0_kij{kij}.txt', 'w') #write to file
    file.write('#time0row7[msb-lsb],time0row6[msb-lst],....,time0row0[msb-lst]#\n')
    file.write('#time1row7[msb-lsb],time1row6[msb-lst],....,time1row0[msb-lst]#\n')
    file.write('#................#\n')
    for j in range(W.size(0)): # per OC (8)
        
        if (kij == 0):
            print(W[j, :, kij])
        for i in range(1, W.size(1), 2):  # per EVEN IC (16)-> 8
            W_bin = z(round(W[j,15-i,kij].item())) # reverse IC
            for k in range(bit_precision):
                file.write(W_bin[k])        
            #file.write(' ')  # for visibility with blank between words, you can use
        
        file.write("\n") # split at middle to fit (7-0) (15-8)
        for i in range(0, W.size(1), 2):  # per ODD IC (16) -> 8
            W_bin = z(round(W[j,15-i,kij].item())) # reverse IC
            for k in range(bit_precision):
                file.write(W_bin[k])      
        file.write('\n')
    file.close() #close file   

# print(W.shape)

# want input  channel to be a row?
# output channel is columns


# OC IC KIJ

# print(output.flatten(1,2).T)

P = output.flatten(1,2).T

print(P.shape)

z = lambda x: ("{0:016b}".format(x) if x >= 0 else "1{0:015b}".format(2**15+x))

# W[:,:,0] = (torch.arange((8*8))%16 - 8).reshape(8,8)

# W = w_tile[tile_id,:,:,kij]  # w_tile[tile_num, array col num, array row num, kij]

bit_precision = 16
file = open(f'out2.txt', 'w') #write to file

file.write('#time0row7[msb-lsb],time0row6[msb-lst],....,time0row0[msb-lst]#\n')
file.write('#time1row7[msb-lsb],time1row6[msb-lst],....,time1row0[msb-lst]#\n')
file.write('#................#\n')
for j in range(P.size(0)): # per TIMESTEP
    for i in range(P.size(1)):  # per OC/col
        W_bin = z(round(P[j,7-i].item())) # reverse OC
        for k in range(bit_precision):
            file.write(W_bin[k])        
        #file.write(' ')  # for visibility with blank between words, you can use
    file.write('\n')
file.close() #close file   


'''
tensor([[-130, -248, -155, -151, -138, -350,   40,  -77],
        [ -74, -241, -159, -194, -125, -243, -104, -186],
        [-135, -180, -184, -261, -242, -262,  -48,  -79],
        [-137, -217,  -69, -193, -133, -225,   28, -111],
        [ -97, -176, -122, -244, -230, -294,   35,  -18],
        [ -31, -186, -139, -192, -122, -278,   -1, -115],
        [-102, -139,  -62, -156, -151, -272,  -71, -126],
        [ -95, -224,  -94, -278, -136, -343,   11,  -53],
        [-133, -285, -126, -206, -136, -247,    4, -104],
        [-103, -109,  -69, -126, -190, -310,  -14,  -17],
        [ -86,  -65, -131, -276, -219, -214,   31,  -92],
        [ -30, -103, -135, -309, -174, -252,  -27, -172],
        [-123, -350, -178, -226, -189, -367,  -20,  -90],
        [  10, -287,  -61, -162, -343, -329, -131, -148],
        [ -30, -240,  -79, -171, -289, -203,   37,  -64],
        [  67, -113,  -62, -235, -256, -356,  -57, -110]])
'''
# print(W.shape)
