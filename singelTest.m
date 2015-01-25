[desc,nodes,satellites,demands] = DataReader('Vrp-All\Instances 2E-VRP\Set3 - aggiornato\E-n51-k5-13-19.dat');%Vrp-All\Instances\Instance50-1.dat');%
[nodeList,depotNum,capacities,distances,demands] = DataAdapter(desc,nodes,satellites,demands);
customerNum = size(nodeList,1) - depotNum;

repeat = 100;
ii = 1;
vehicleNum = desc(7);
bestSolution = int32(zeros(1,depotNum*(customerNum+5)));
bestCost = 1000000;
costs1 = 1000000;
costs2 = 1000000;
bestindex = 1;

routes = [];
while ii < repeat
    routes = AllocatePhase3(nodeList,depotNum,vehicleNum,capacities,distances,demands,routes);
    maxSolutionLen = customerNum + vehicleNum + 1; %默认每个depot有四辆车
    gpuRoute = gpuArray(routes);
    randInt = gpuArray(int32(randi(1000000,1,1000)));
    randDouble = gpuArray(rand(1,1000));
    gpuCapacities = gpuArray(capacities);
    
    k = parallel.gpu.CUDAKernel('kernel.ptx','kernel.cu','simulatedAnnealingKernel');
    k.ThreadBlockSize = double([depotNum 1]);
    costs = gpuArray(zeros(1,depotNum));
    [routes,costs] = feval(k,gpuRoute,costs,maxSolutionLen,demands,distances,int32(size(nodeList,1)),gpuCapacities,randInt,randDouble,10000,0.001);
    routes = gather(routes);
    costs = gather(costs);
    
    depotList = nodes(1,1:2);
    vNum = desc(6);
    capacity = desc(4);
    [nd,dn,dis,dems ]...
        = DataForPhase2(depotList,satellites,demands,routes,maxSolutionLen);
    [x,fval,exitflag,output] = AllocatePhase2(nd,dn,vNum,capacity,dis,dems);
    if sum(costs)+fval < bestCost
        bestCost = sum(costs)+fval;
        costs1 = fval;
        costs2 = sum(costs);
        bestIndex = ii;
    end
    fprintf(1,'%d\n',ii);
    ii = ii+1;
    if ii==5
        fprintf(1,'stop\n');
    end
end
%% store the result in excel
%dataRecord = {'dataPath','ns','costs','costs1','costs2'}
dataRecord = {strcat(directory,dataSets(i).name,'\',dataSources(i).name),desc(2),bestCost,costs1,costs2};
xlswrite('result\twoPhaseResult.xls',dataRecord,'version1',strcat('A',num2str(counter)));