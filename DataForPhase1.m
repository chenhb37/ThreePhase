function[ nodeNum,depotNum,distances,dems ]...
= DataForPhase1(x,depotList,satelliteList,customerNum)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
   depotNum = size(depotList,1);
   nodeNum = depotNum + customerNum;
   nodeList = [depotList;satelliteList];
   distances = GetDistanceMatrix(nodeList);
   dems = zeros(nodeNum,1);
   nodeNumTemp = sqrt(size(x,1)/2);
   for i = depotNum+1:nodeNum
        for j = 1:nodeNumTemp
            if x((i-depotNum-1)*nodeNumTemp+j) == 1
                de = x(nodeNumTemp^2 + (i-depotNum-1)*nodeNumTemp+j);
                dems(i) = dems(i) + de;
            end
        end
   end
end



