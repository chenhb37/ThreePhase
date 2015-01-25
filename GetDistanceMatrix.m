function distanceMatrix = GetDistanceMatrix(nodes)
%% To get the distance between all the nodes
% nodes:coordinate matrix of nodes including the depot
% distanceMatrix: the distance matrix between each pair nodes
    n = size(nodes,1); %size of nodes
    distanceMatrix = zeros(n); 
    for i = 1:1:n
        obj = [nodes(i,1).*ones(n,1), nodes(i,2).*ones(n,1)];
        temp = (obj - [nodes(1:n,1), nodes(1:n,2)]).^2;
        distanceMatrix(1:n,i) = sqrt(temp(1:n,1)+temp(1:n,2));
    end
end