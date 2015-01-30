function [ routes ] = AllocatePhase3(nodeNum,depotNum,vNum,capacity,distances,demands,routes)
% funtion: ���ݵ�ǰ��״̬��������depot��������
%       1�� ��ʼ״̬�¸���customer������depot�ľ�����з��䣬ÿ��cusomter�������ܵķ��䵽�����depot
%       2,  ��̬�¸���depot�ĳ���Ч�ʣ�rouDis/Load, rouDis Ϊ·���ܳ��ȣ�Load��·���ܵĸ��أ�����������Ϊ
%            ��λ������Ҫ��������з��䣬
%param:
%       nodeList: �ڵ��б�����depot�ڵ��customer�ڵ�
%       depotNum: nodeList�У�ǰdepotNum���ڵ����depot�ڵ�'
%       capacities:���������ܹ����ص����������,ĳ�����ĵ���������������Ϊ��������������ܺ�
%       distances: �����֤��distances(i,j)��ʾ�ڵ�i���ڵ�j��ŷʽ����
%       demands: �ͻ����������б�
%       routes: ֮ǰ����ĸ���װ�����ĵ�·��
%% ��ʼ״̬
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
    
    %% ��̬�µ�
else
    depotEff = zeros(1,depotNum);
    for i =1: depotNum
        route = routes((i-1)*maxSolutionLen+1:i*maxSolutionLen);
        rdi =  GetRouteDistance(route,distances);
        rde =  GetRouteDemand(route,demands)+1;
        depotEff(i) =rdi/double(rde);%��ֹ���ַ�ĸΪ0���������depot
    end
    [~,lowEffDepot] = max(depotEff);
    route = routes((lowEffDepot-1)*maxSolutionLen+1:lowEffDepot*maxSolutionLen);
    customerEff = GetCustomerEff(lowEffDepot,route,distances,demands);
    %ѡ��Ҫ�޳��Ŀͻ�
    [~,lowEffCusIndex] = max(customerEff);
    lowEffCus = routes((lowEffDepot-1)*maxSolutionLen+lowEffCusIndex);
    if lowEffCus <= depotNum
        display('error');
    end
    %ɾ���ͻ�
    i = lowEffCusIndex;
    while route(i)~=0
        route(i) = route(i+1);
        i = i+1;
    end
    routes((lowEffDepot-1)*maxSolutionLen+1:lowEffDepot*maxSolutionLen)=route;
    %���ÿͻ����䵽��������Ŀ���depot(���˵�ǰ��depot��
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
%       ��ʼ״̬�¸���customer������depot�ľ�����з��䣬ÿ��cusomter�������ܵķ��䵽�����depot
%       �������depot�Ѿ����ˣ������滻����һ���ڵ�ʹ�ø�������û�нڵ���滻�����Ǿ���ڶ�����depot
% param:
%       nodeList: �ڵ��б�����depot�ڵ��customer�ڵ�
%       depotNum: nodeList�У�ǰdepotNum���ڵ����depot�ڵ�'
%       capacities:���������ܹ����ص����������
%       distances: �����֤��distances(i,j)��ʾ�ڵ�i���ڵ�j��ŷʽ����
%       demands: �ͻ����������б�
%       routes: ֮ǰ����ĸ���װ�����ĵ�·��
%       customer: ��ǰ��Ҫ������Ŀͻ��ڵ�
depotFlag = zeros(1,depotNum);
diatanceFlag = zeros(size(depotFlag));

%���䵽customer�ľ����С�����������
for i = 1:depotNum
    diatanceFlag(i) = distances(i,customer);
    depotFlag(i) = i;
    %����
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
%����ڵ�
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
    else%�滻����
        eff = GetCustomerEff(depot,curRoute,distances,demands);
        [value,replace] = max(eff);
        curEff = distances(customer,depot)/(demands(customer)+1);
        
        %����滻�� ��Ȼ����վ������������Լ����������滻
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
    eff(i) = distances(customer,depot)/(demands(customer)+1);%��ֹ���ַ�ĸΪ0
end
end
