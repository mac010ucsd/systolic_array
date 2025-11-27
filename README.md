# systolic_array
## todo
- [x] mac tile 2-4 bit switchable
- [x] mac tile tb
- [ ] mac row
- [ ] mac row tb
- [ ] mac array
- [ ] mac array tb
- [ ] etc

## notes

In 2-bit mode,
psum width = 9 bits (8 tiles x 4-bit weight x 2-bit act = 2^{3+4+2=9})

In 4-bit mode, 11-bit psum is reconstructed from 9-bit PSUM0 and PSUM1. `reconstructed_psum = {2'b00, PSUM0} | {PSUM1, 2'b00}`. In other words, (output) psums for 4-bit mode are 9-bit `PSUM1 = {full_psum[10:8], 6'b0}`, `PSUM0 = {1'b0, full_psum[7:0]}`, 

Alternatively we can decide to just make the PSUM width 11-bit so we can pass the entire 4x4bit x8 PSUM, and not have to worry about PSUM shifting and whatever. 