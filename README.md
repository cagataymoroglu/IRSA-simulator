# irsa
A generalized Matlab implementation of the Irregular Repetition Slotted Aloha MAC layer

Successive Interference Cancellation and Replica Generation algorithms are taken from https://github.com/afcuttin/irsa, which includes the files: LICENSE, generateTwins.m and sic.m.

Functions:

    irsa_sim.m calculates the normalized load,the normalized throughput and packet loss Rates per degree by using single channel, with given parameters "sourceNumber, randomAccessFrameLength, packetReadyProb, degree, simulationTime, maxIter".

    GenerateTwins.m return the MAC frame includes twins.

    sic.m makes successive interference cancelation, and returns MAC frame with unsolved packets, solved users, and solved packets information.

Scripts:

    SampleSCRforIRSAsimulator.m is a sample script for IRSA simulator.
