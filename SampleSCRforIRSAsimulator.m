clear
clc

randomAccessFrameLength = 100;
sourceNumber = 90;
simulationTime = 1e2;
packetReadyProb = 1;
degree = [0 0.5631 0.0436 0 0.3933];

[loadNorm,throughputNorm,packetLossRatio_per_degree] = irsa_sim(sourceNumber,randomAccessFrameLength,packetReadyProb,degree,simulationTime);
