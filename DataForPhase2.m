function dems= DataForPhase2( depotNum,customerNum,demands,routes,rl)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
nodeNum = depotNum + customerNum;
dems = zeros(1,nodeNum);
for i = depotNum+1:nodeNum
    depot = i - depotNum;
    dems(i) = GetRouteDemand(routes((depot-1)*rl+1:depot*rl),demands);
end
end

