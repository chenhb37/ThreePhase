function [ nodeNum,depotNum,distances,dems ]...
= DataForPhase2( depotList,satelliteList,demands,routes,rl)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
depotNum = size(depotList,1);
nodeNum = depotNum + size(satelliteList,1);
nodeList = [depotList;satelliteList];
distances = GetDistanceMatrix(nodeList);
dems = zeros(1,nodeNum);
for i = depotNum+1:nodeNum
    depot = i - depotNum;
    dems(i) = GetRouteDemand(routes((depot-1)*rl+1:depot*rl),demands);
end
end

