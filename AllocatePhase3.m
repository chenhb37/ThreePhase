function [ routes ] = AllocatePhase3(nodeNum,depotNum,vNum,capacity,distances,demands,routes)
% funtion: 根据当前的状态调整各个depot的运输量
%       1， 初始状态下根据customer到各个depot的距离进行分配，每个cusomter都尽可能的分配到最近的depot
%       2,  常态下根据depot的承载效率（rouDis/Load, rouDis 为路径总长度，Load是路径总的负载，其物理意义为
%            单位负载索要）对其进行分配，
%param:
%       nodeList: 节点列表，包括depot节点和customer节点
%       depotNum: nodeList中，前depotNum个节点就是depot节点'
%       capacities:各个中心能够承载的最大运输量,某个中心的最大运输量可理解为车俩的最大容量总和
%       distances: 距离举证，distances(i,j)表示节点i到节点j的欧式距离
%       demands: 客户的需求量列表
%       routes: 之前计算的各个装配中心的路径
%% 初始状态
maxSolutionLen = nodeNum-depotNum + 1 + vNum; 

if isempty(routes)
    routes = int32(zeros(1,maxSolutionLen*depotNum));
    for i = 1:depotNum
        routes((i-1)*maxSolutionLen+1:(i-1)*maxSolutionLen+1+vNum) = i.* int32(ones(1,1+vNum));
    end
    for i = depotNum+1:nodeNum
        customer = i;
        depotSeq = SortDepotInDistance(depotNum,distances,customer);
        [successFlag,customer,routes] = AllocateCusToDepot(depotSeq,capacity,distances,demands,routes,maxSolutionLen,customer);
        while successFlag == 0
            depotSeq = SortDepotInDistance(depotNum,distances,customer);
            [successFlag,customer,routes] = AllocateCusToDepot(depotSeq,capacity,distances,demands,routes,maxSolutionLen,customer);
        end
    end
    
    %% 常态下的
else
    depotEff = zeros(1,depotNum);
    for i =1: depotNum
        route = routes((i-1)*maxSolutionLen+1:i*maxSolutionLen);
        rdi =  GetRouteDistance(route,distances);
        rde =  GetRouteDemand(route,demands)+1;
        depotEff(i) =rdi/double(rde);%防止出现分母为0的情况，空depot
    end
    [~,lowEffDepot] = max(depotEff);
    route = routes((lowEffDepot-1)*maxSolutionLen+1:lowEffDepot*maxSolutionLen);
    customerEff = GetCustomerEff(lowEffDepot,route,distances,demands);
    %选择要剔除的客户
    [~,lowEffCusIndex] = max(customerEff);
    lowEffCus = routes((lowEffDepot-1)*maxSolutionLen+lowEffCusIndex);
    if lowEffCus <= depotNum
        display('error');
    end
    %删除客户
    i = lowEffCusIndex;
    while route(i)~=0
        route(i) = route(i+1);
        i = i+1;
    end
    routes((lowEffDepot-1)*maxSolutionLen+1:lowEffDepot*maxSolutionLen)=route;
    %将该客户分配到离其最近的可用depot(除了当前的depot）
    depotSeq = SortDepotInDistance(depotNum,distances,lowEffCus);
    for i = 1:depotNum
        depotTemp = depotSeq(i);
        routeDemand = GetRouteDemand(routes((depotTemp-1)*maxSolutionLen+1:(depotTemp)*maxSolutionLen),demands);
        if depotSeq(i)~= lowEffDepot && routeDemand + demands(lowEffCus) < capacity;
            route = routes((depotTemp-1)*maxSolutionLen+1:(depotTemp*maxSolutionLen));
            [~,len] = min(route);
            ip = 1+randi(len-2);
            for j =len:-1:ip+1
                 route(j) = route(j-1);
            end
            route(ip) = lowEffCus;
            routes((depotTemp-1)*maxSolutionLen+1:(depotTemp)*maxSolutionLen) = route;
            break;
        end
    end 
end
end
function  depotFlag = SortDepotInDistance(depotNum,distances,customer)
% function:
%       初始状态下根据customer到各个depot的距离进行分配，每个cusomter都尽可能的分配到最近的depot
%       当最近的depot已经满了，考虑替换其中一个节点使得更合理，若没有节点可替换，则考虑距离第二近的depot
% param:
%       nodeList: 节点列表，包括depot节点和customer节点
%       depotNum: nodeList中，前depotNum个节点就是depot节点'
%       capacities:各个中心能够承载的最大运输量
%       distances: 距离举证，distances(i,j)表示节点i到节点j的欧式距离
%       demands: 客户的需求量列表
%       routes: 之前计算的各个装配中心的路径
%       customer: 当前需要被分配的客户节点
depotFlag = zeros(1,depotNum);
diatanceFlag = zeros(size(depotFlag));

%按其到customer的距离从小到大进行排序
for i = 1:depotNum
    diatanceFlag(i) = distances(i,customer);
    depotFlag(i) = i;
    %排序
    if i >= 2
        for j = i:-1:2
            if diatanceFlag(j) < diatanceFlag(j-1)
                temp = diatanceFlag(j);
                diatanceFlag(j) = diatanceFlag(j-1);
                diatanceFlag(j-1) = temp;
                
                temp = depotFlag(j);
                depotFlag(j) = depotFlag(j-1);
                depotFlag(j-1) = temp;
            end
        end
    end
end
end
function [successFlag,customer,routes] = AllocateCusToDepot(depotSeq,capacity,distances,demands,routes,solutionLen,customer)
%分配节点
successFlag = 1;
depotNum = size(depotSeq,2);
for depotIndex = 1:depotNum
    depot = depotSeq(depotIndex);
    curRoute = routes((depot-1)*solutionLen+1:depot*solutionLen);
    totalDemand = GetRouteDemand(curRoute,demands);
    if totalDemand + demands(customer) <= capacity
        [~,i] = min(curRoute);
        curRoute(i) = curRoute(i-1);
        curRoute(i-1) = customer;
       
        routes((depot-1)*solutionLen+1:depot*solutionLen) = curRoute;
        successFlag = 1;
        break;
    else%替换策略
        eff = GetCustomerEff(depot,curRoute,distances,demands);
        [value,replace] = max(eff);
        curEff = distances(customer,depot)/(demands(customer)+1);
        
        %如果替换后 依然满足站点的最大运输量约束，则进行替换
        if curEff < value && totalDemand -demands(curRoute(replace)) + demands(customer) <= capacity
            temp =curRoute(replace);
            curRoute(replace) = customer;
            customer = temp;
            routes((depot-1)*solutionLen+1:depot*solutionLen) = curRoute;
            successFlag = 0;
            break;
        end
       
    end
end
end
function eff = GetCustomerEff(depot,route,distances,demands)
[~,len] = min(route);
eff = zeros(1,len-1);
for i = 1:size(eff,2)
    customer = route(i);
    eff(i) = distances(customer,depot)/(demands(customer)+1);%防止出现分母为0
end
end
