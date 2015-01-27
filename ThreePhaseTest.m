%AllocatePhase3Test
directory = 'Vrp-All\Instances 3E-VRP\';
dataSets = dir(directory);
counter = 1;
duplicate = 5;
for setCounter = 1:size(dataSets,1)
    if dataSets(setCounter).isdir ==1 && strcmp(dataSets(setCounter).name,'.') ==0 && strcmp(dataSets(setCounter).name,'..') == 0 &&strcmp(dataSets(setCounter).name,'Set1 - aggiornato')==0 ...
        && strcmp(dataSets(setCounter).name,'Set4 - aggiornato')==0
        dataSources = dir(strcat(directory,dataSets(setCounter).name,'\F*.dat'));
        for sourceCounter = 1:size(dataSources,1)
            time1 = now;
            fileName = strcat(directory,dataSets(setCounter).name,'\',dataSources(sourceCounter).name);
            fprintf(1,'%s\n',fileName);
            for kk = 1: duplicate
            [desc,nodes,satellites1,satellites2,demands] = DataReaderForPh3(fileName);%Vrp-All\Instances\Instance50-1.dat');%
            tempDesc = [desc(1)-desc(2),desc(3),desc(4),0,desc(7),0,desc(10)];
            [nodeList,depotNum,capacities,distances,demands3] = DataForPhase3(tempDesc,nodes,satellites2,demands);
            customerNum = size(nodeList,1) - depotNum;
            
            repeat = 100;
            ii = 1;
            vehicleNum = desc(10);
            bestSolution = int32(zeros(1,depotNum*(customerNum+5)));
            bestCost = 1000000;
            costs1 =0;
            costs2 =0;
            costs3 =0;
            bestindex = 1;
            routes = [];
            while ii < repeat
                routes = AllocatePhase3(nodeList,depotNum,vehicleNum,capacities,distances,demands3,routes);
                maxSolutionLen = customerNum + vehicleNum + 1; %默认每个depot有四辆车
                gpuRoute = gpuArray(routes);
                randInt = gpuArray(int32(randi(1000000,1,1000)));
                randDouble = gpuArray(rand(1,1000));
             
         
                k = parallel.gpu.CUDAKernel('kernel.ptx','kernel.cu','simulatedAnnealingKernel');
                k.ThreadBlockSize = double([depotNum 1]);
                costs = gpuArray(zeros(1,depotNum));

                nodeNum = int32(size(nodeList,1));
                cap = desc(7);
                vNum = desc(10);
                [routes,costs] = feval(k,gpuRoute,costs,maxSolutionLen,demands3,distances,nodeNum,cap,vNum,randInt,randDouble,10000,0.001);
                routes = gather(routes);
                costs = gather(costs);
                
                %phase 2
                depotList = satellites1;
                capacity = desc(6);
                [nd,dn,dis,dems ]...
                    = DataForPhase2(depotList,satellites2,demands3,routes,maxSolutionLen);
                vNum = double(desc(6)) .* ones(1,dn);
                [x2,fval2,~,~] = AllocatePhaseCplex(nd,dn,vNum,capacity,dis,dems);
                
                %phase 1
                depotList = nodes(1,1:2);
                capacity = desc(5);
                [nd,dn,dis,dems ]...
                    = DataForPhase1(x2,depotList,satellites1,dn);
                vNum = double(desc(8)) .* ones(1,dn);
                [x1,fval1,exitflag,output] = AllocatePhaseCplex(nd,dn,vNum,capacity,dis,dems);
              
              
                if sum(costs)+fval2+fval1 < bestCost
                    bestCost = sum(costs)+fval2+fval1;
                    costs1 = fval1;
                    sm1 = Edge2StringModel(x1,size(satellites1,1));
                    costs2 = fval2;
                    sm2 = Edge2StringModel(x2,size(satellites2,1));
                    costs3 = sum(costs);
                    sm3 = Gpu2StringModel(routes,maxSolutionLen);
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
            dataRecord = {strcat(directory,dataSets(setCounter).name,'\',dataSources(sourceCounter).name),desc(2),desc(3),bestCost,costs1,costs2,costs3,num2str(sm1),num2str(sm2),num2str(sm3),num2str(tcs)};
            [status,message]= xlswrite('result\ThreePhaseResult.xls',dataRecord,'version1',strcat('A',num2str(counter)));
            counter = counter + 1;
            end
        end
    end
end
%                 %%  
%                 spec = '%d';
%                 for i = 1:maxSolutionLen-1
%                     spec = strcat(spec,' %d ');
%                 end
%                 spec = strcat(spec,'\n');
% 
%                 fId = fopen('routes.txt','w');
%                 fprintf(fId,spec,gpuRoute);
%                 fclose(fId);
% 
%                 spec = '%d %d\n';
%                 fId = fopen('randInt.txt');
%                 fprintf(fId,spec,randInt);
% 
%                 spec = '%12.8f %12.8f\n';
%                 fId = fopen('randDouble.txt');
%                 fprintf(fId,spec,randDouble);
% 
%                 fId = fopen('demands.txt','w');
%                 fprintf(fId,'%d\n',demands3);
%                 fclose(fId);
%                 spec ='%12.8f';
%                 for i = 1:size(nodeList,1)-1
%                     spec=strcat(spec,' %12.8f');
%                 end
%                 spec=strcat(spec,'\n');
%                 fId = fopen('distances.txt','w');
%                 fprintf(fId,spec,distances);
%                 fclose(fId);
% %%



