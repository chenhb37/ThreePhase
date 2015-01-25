%AllocatePhase3Test
directory = 'Vrp-All\Instances 2E-VRP\';
dataSets = dir(directory);
counter = 1;
duplicate = 5;
for setCounter = 1:size(dataSets,1)
    if dataSets(setCounter).isdir ==1 && strcmp(dataSets(setCounter).name,'.') ==0 && strcmp(dataSets(setCounter).name,'..') == 0 &&strcmp(dataSets(setCounter).name,'Set1 - aggiornato')==0 ...
        && strcmp(dataSets(setCounter).name,'Set4 - aggiornato')==0
        dataSources = dir(strcat(directory,dataSets(setCounter).name,'\*.dat'));
        for sourceCounter = 1:size(dataSources,1)
            time1 = now;
            fileName = strcat(directory,dataSets(setCounter).name,'\',dataSources(sourceCounter).name);
            fprintf(1,'%s\n',fileName);
            for kk = 1: duplicate
            [desc,nodes,satellites,demands] = DataReader(fileName);%Vrp-All\Instances\Instance50-1.dat');%
            [nodeList,depotNum,capacities,distances,demands] = DataForPhase3(desc,nodes,satellites,demands);
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
                cap = desc(5);
                vNum = desc(7);
                [routes,costs] = feval(k,gpuRoute,costs,maxSolutionLen,demands,distances,int32(size(nodeList,1)),cap,vNum,randInt,randDouble,10000,0.001);
                routes = gather(routes);
                costs = gather(costs);
                
                %phase 2
                depotList = nodes(1,1:2);
                capacity = desc(4);
                [nd,dn,dis,dems ]...
                    = DataForPhase2(depotList,satellites,demands3,routes,maxSolutionLen);
                vNum = double(desc(6)) .* ones(1,dn);
                [x,fval,exitflag,output] = AllocatePhaseCplex(nd,dn,vNum,capacity,dis,dems);
                if sum(costs)+fval < bestCost
                    bestCost = sum(costs)+fval;
                    costs1 = fval;
                    s1 = Edge2StringModel(x,size(satellites,1));
                    costs2 = sum(costs);
                    s2 = Gpu2StringModel(routes,maxSolutionLen);
                    bestIndex = ii;
                end
                %fprintf(1,'%d\n',ii);
                ii = ii+1;
            end
            time2 = now;
            tc = time2 - time1;
            tcs = day(tc)*3600*24+hour(tc)*3600+minute(tc)*60+second(tc);
           %% store the result in excel
            %dataRecord = {'dataPath','ns','costs','costs1','costs2'}
            dataRecord = {strcat(directory,dataSets(setCounter).name,'\',dataSources(sourceCounter).name),desc(2),bestCost,costs1,costs2,num2str(s1),num2str(s2),num2str(tcs)};
            xlswrite('result\twoPhaseResult.xls',dataRecord,'version1.1',strcat('A',num2str(counter)));
            counter = counter + 1;
            end
        end
    end
end

%%
%     spec = '%d';
%     for i = 1:maxSolutionLen-1
%         spec = strcat(spec,' %d ');
%     end
%     spec = strcat(spec,'\n');
%
%     fId = fopen('routes.txt','w');
%     fprintf(fId,spec,gpuRoute);
%     fclose(fId);
%
%     spec = '%d %d\n';
%     fId = fopen('randInt.txt');
%     fprintf(fId,spec,randInt);
%
%     spec = '%12.8f %12.8f\n';
%     fId = fopen('randDouble.txt');
%     fprintf(fId,spec,randDouble);
%
%     fId = fopen('demands.txt','w');
%     fprintf(fId,'%d\n',demands);
%     fclose(fId);
%     spec ='%12.8f';
%     for i = 1:size(nodeList,1)-1
%         spec=strcat(spec,' %12.8f');
%     end
%     spec=strcat(spec,'\n');
%     fId = fopen('distances.txt','w');
%     fprintf(fId,spec,distances);
%     fclose(fId);
%%



