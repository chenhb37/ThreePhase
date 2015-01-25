function [nodeList,depotNum,capacities,distances,demands] = DataForPhase3(desc,nodes,satellites,demands)
%DATAADAPTER Summary of this function goes here
%   Detailed explanation goes here
U = 10;
depotNum = desc(2);
depotList = satellites;
customerList = [nodes(2:desc(1)-desc(2),1),nodes(2:desc(1)-desc(2),2)];
nodeList = [depotList;customerList];
vc = desc(5);
vn = desc(7);
capacities = vn * vc .* int32(ones(1,depotNum));
distances = GetDistanceMatrix(nodeList);
% for i = 1:depotNum
%     distances(i,depotNum+1:size(nodeList,1))= distances(i,depotNum+1:size(nodeList,1))+0.5*U;
%     distances(depotNum+1:size(nodeList,1),i)= distances(depotNum+1:size(nodeList,1),i)+0.5*U;
% end
dd = zeros(1,depotNum)';
cd =demands(2:desc(1)-desc(2));
demands = [dd;cd];
end

