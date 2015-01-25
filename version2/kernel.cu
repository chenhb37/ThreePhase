//verison 2
#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <math.h>
#include <fstream>
#include <cuda.h>
#include <device_functions.h>

using namespace std;
#define SIZE 10240
#define MAXVN 10


__global__ void addKernel(double *c, const double *a, const double *b)
{
    int i = threadIdx.x;
	c[i] = exp(a[i]+b[i]);
}
 
__global__ void simulatedAnnealingKernel(int *route,
										 double * costs,
										 const int solutionLen,
										 const int *demands,
										 const double * distances,
										 const int nodeNum,
										 const int *capacities,
										 const int *randInt,
										 const double *randDouble,
										 const double tempParam,
										 const double cr)
{ 
	int depot = threadIdx.x;
	int *bestSolution = route + (depot)*solutionLen;
	__shared__ int solutionArray[SIZE];

	//每个线程分配3*solutonLen*4 Byte 大小的共享内存
	 
	//共享内存变量  
	int *solution = &solutionArray[threadIdx.x*(solutionLen*2+6*MAXVN)]; //solutionLen
	
    int *curSolution = (int *)&solution[solutionLen];  //solutionLen
	double *dice =(double*)&curSolution[solutionLen];
	int *cusIndex = (int*)&dice[1];
	int *range = (int*)&cusIndex[1];
	int *v = (int*)&range[1];
	int *improvedTryCounter = (int*)&v[1];
    int *demandCounter=(int*)&improvedTryCounter[MAXVN]; //4
	int *routeStart=(int*)&demandCounter[MAXVN];  //6
	double *acc = (double*)&routeStart[MAXVN+1];    //5
	

	//寄存器变量
	/*int demandCounter[4]={0};
	int routeStart[6] = {0};
	double acc[5] = {0};*/

    int maxDemandIndex = 0;
	double demandSum = 0;
    double minCost = 100000;
    int insertPoint = 0;
    int cus=0;
	double cost=0;
	int pre=0;
	int cur=0;
	int i=0;
	int maxDemand=0;
	int *r1=v;
	int *r2=range;
	int *inter =cusIndex;
	int nextRand = 0;
	int strategy = 0;
	double temp = tempParam;//cr = 0.001;//tempPara;
	


	//计算距离
	double dis = 0;
	int len = 1;
	for(int i =1; bestSolution[i]!=0; i++){
		  pre = bestSolution[i-1];
		  cur = bestSolution[i];
		  dis += distances[(pre-1)*nodeNum+cur-1];
		  len ++;
	}

	for(int i =0; i< len; i++){
		solution[i] = bestSolution[i];
	    curSolution[i] = bestSolution[i];
     }

	costs[depot] = dis;
	
	improvedTryCounter[0] = 1;
	improvedTryCounter[1] = 1;
	improvedTryCounter[2] = 1;
	
	while(temp > 0.01){
	     //选择策略
	    *dice =randDouble[(nextRand+threadIdx.x*20)%1000];
		nextRand =(nextRand+1)%1000;
		if(*dice <= 1){//0.1+0.7*(improvedTryCounter[0]/(double)(improvedTryCounter[0]+improvedTryCounter[1]+improvedTryCounter[2]))
			//选择策略0
			strategy = 0;
		    *r1 = 1+randInt[(nextRand+threadIdx.x*20)%1000]%(len-2);
			nextRand = (++nextRand)%1000;
		    *r2 = 1+randInt[(nextRand+threadIdx.x*20)%1000]%(len-2);
			nextRand = (++nextRand)%1000;
			//swap *r1,*r2 in solution
		    *inter = solution[*r1];
			solution[*r1] = solution[*r2];
			solution[*r2] = *inter;
		}
		else if(*dice <= 0.1+0.7*((improvedTryCounter[0]+improvedTryCounter[1])/(double)(improvedTryCounter[0]+improvedTryCounter[1]+improvedTryCounter[2]))){
		    //选择策略1
			//统计各个车俩的负载，根据车辆的负载调整
			strategy = 1;
			
            maxDemandIndex = 0;
			demandSum = 0;
		    *v = 0;
			demandCounter[*v] = 0;
			routeStart[*v] = 0;
			for(i = 1;i<len; i++){
			    if (solution[i] == depot+1){
                    if( demandCounter[*v] > demandCounter[maxDemandIndex])
                         maxDemandIndex = *v;
					(*v)++;
					demandCounter[*v] = 0;
					routeStart[*v] = i;
				}
				else{
					demandCounter[*v]+= demands[solution[i]-1];
				    demandSum += demands[solution[i]-1];
				}
			}
			
			acc[0] = demandCounter[0]/(demandSum+0.1);
			for(i = 1; i< 4; i++){
			     acc[i] = acc[i-1]+demandCounter[i]/(demandSum+0.1);
			}
			acc[i-1] = 1;

			*dice =randDouble[(nextRand+threadIdx.x*20)%1000];
			nextRand = (++nextRand)%1000;
			*v = 0;
			while(*dice>acc[*v]) (*v)++; //找到对应的车为v
			//从v中抽取一个客户然后将其插入到其他的车的适当路线位置 而客户的位置应该在routeStart[*v]和routeStart[v+1]之间
		    *range = routeStart[*v+1]-routeStart[*v]-1;
			if(*range ==0)
				continue;
		    *cusIndex = routeStart[*v]+1+randInt[(nextRand+threadIdx.x*20)%1000]%*range;
			nextRand = (++nextRand)%1000;


            //按概率选择负载较小的车
		    maxDemand = demandCounter[maxDemandIndex];
			acc[0] = (maxDemand - demandCounter[0])/(4*maxDemand - demandSum+0.1);
			for(i =1; i< 4; i++){
			    acc[i] = acc[i-1]+(maxDemand - demandCounter[i])/(4*maxDemand - demandSum+0.1);
			}
			acc[i-1] = 1;

			//更新demandCounter
			demandCounter[*v] -= demands[solution[*cusIndex]-1];

			*dice =randDouble[(nextRand+threadIdx.x*20)%1000];
			nextRand = (++nextRand)%1000;

			*v = 0;
			while(*dice>acc[*v]) (*v)++; //找到对应的车为*v 其范围为routeStart[*v]到routeStart[*v+1]

			//更新demandCounter
			demandCounter[*v] += demands[solution[*cusIndex]-1];

		    minCost = 100000;
		    insertPoint = 0;
		    cus = solution[*cusIndex];
			cost = 0;
			//将*cusIndex对应的客户插入到车辆*v对应的路径中合适的位置
            for(i = routeStart[*v]; i<routeStart[*v+1]; i++){
				   cost = distances[(cus-1)*nodeNum+solution[i]-1]+
					      distances[(cus-1)*nodeNum+solution[i+1]-1]-
						  distances[(solution[i]-1)*nodeNum+solution[i+1]-1];
				   if(cost < minCost){
					   minCost =cost;
					   insertPoint = i;
				   }
			}

		    //将cus从*cusIndex的位置插入到insertPoint的位置
			if( *cusIndex <insertPoint){
			   for(int i = *cusIndex; i <insertPoint; i++){
			         solution[i] = solution[i+1];
			   }
			   solution[insertPoint] = cus;
			}else{
			   for(int i = *cusIndex; i >insertPoint+1; i--){
			          solution[i] = solution[i-1];
			   }
			   solution[insertPoint+1] = cus;
			}
		}
		//strategy 3 insertion
		else{
		    strategy = 2;
			*r1 = 1+randInt[(nextRand+threadIdx.x*20)%1000]%(len-2);
			nextRand = (++nextRand)%1000;
		    *r2 = 1+randInt[(nextRand+threadIdx.x*20)%1000]%(len-2);
			nextRand = (++nextRand)%1000;
			*inter = solution[*r1];
			if(*r1<*r2){
			  for(int i =*r1;i<*r2;i++){
			     solution[i] = solution[i+1];
			  }
			  
			}else if(*r1>*r2){
				for(int i =*r1; i>*r2; i--){
				   solution[i] = solution[i-1];
				}
			}
			solution[*r2] = *inter;
		}
		//计算新解的总距离
		double newDis = 0;
	    for(i =1; i<len-1;i++){
		  pre = solution[i];
		  cur = solution[i+1];
		 newDis += distances[(pre-1)*nodeNum+cur-1];
	    }
		//判断新解是否满足容量约束
		for(i=0; i<4; i++){
		   if(demandCounter[i] > capacities[depot]/4){
		      newDis += capacities[depot];
		   }
		}

		//如果新解比当前解更优，替换
		if(newDis < dis){
			for(i = 0;i< len; i++){
				curSolution[i] = solution[i];
			}
			dis = newDis;
			improvedTryCounter[strategy] ++;
			//如果比最优解更优，替换最优解
			if( newDis < costs[depot]){
				for(i =0; i< len; i++){
				   bestSolution[i] = solution[i];
				}
				costs[depot] = newDis;
			}
		}else{
			//否则以概率 exp((dis - newDis)/temp)替换
			*dice =randDouble[(nextRand+threadIdx.x*20)%1000];
			nextRand = (++nextRand)%1000;
			if(*dice < exp((dis - newDis)/temp)){
			     for(i = 0;i< len; i++){
				   curSolution[i] = solution[i];
			     }
			     dis = newDis;
			}
		}
		temp *=1 - cr;
		__syncthreads(); 
	}
}


int main(){
	const int nodeNum = 97;
	const int depotNum = 9;
	const int vehicleNum = 3;
	const int solutionLen = nodeNum - depotNum + vehicleNum + 1;
	int r[depotNum*solutionLen] = {0};
	int demand[nodeNum] = {0};
	double dis[nodeNum*nodeNum]={0};
	double randDouble[1000] = {};
	int randInt[1000] ={};

	ifstream routeStream("routes.txt");
	ifstream distanceStream("distances.txt");
	ifstream demandStream("demands.txt");
	ifstream rdStream("randDouble.txt");
	ifstream riStream("randInt.txt");
	for(int i=0; i<depotNum; i++){
		for(int j =0; j< solutionLen; j++){
			 routeStream>>r[i*solutionLen+j];
		}
	}
	for(int i=0; i<nodeNum; i++){
		demandStream>>demand[i];
		for(int j = 0; j< nodeNum; j++){
		    distanceStream>>dis[i*nodeNum + j];
		}
	}

	for(int i=0; i<1000; i++){
	    rdStream>>randDouble[i];
		riStream>>randInt[i];
	}
	routeStream.close();
	distanceStream.close();
	demandStream.close();
	riStream.close();
	rdStream.close();

	double costs[depotNum]={0};
	cudaError e;

	int* d_r;
	e = cudaMalloc((void**)&d_r,sizeof(int)*depotNum*solutionLen);
    e = cudaMemcpy(d_r,r,sizeof(int)*depotNum*solutionLen,cudaMemcpyHostToDevice);

	double* d_costs;
	e = cudaMalloc((void**)&d_costs,sizeof(double)*depotNum);

	int *d_demand;
	e = cudaMalloc((void**)&d_demand,sizeof(int)*nodeNum);
	e = cudaMemcpy(d_demand,demand,sizeof(int)*nodeNum,cudaMemcpyHostToDevice);

    double *d_dis;
	e = cudaMalloc((void**)&d_dis,sizeof(double)*nodeNum*nodeNum);
	e = cudaMemcpy(d_dis,dis,sizeof(double)*nodeNum*nodeNum,cudaMemcpyHostToDevice);

    int *d_randInt;
    e = cudaMalloc((void**)&d_randInt,sizeof(int)*1000);
	e = cudaMemcpy(d_randInt,randInt,sizeof(int)*1000,cudaMemcpyHostToDevice);

	double *d_randDouble;
	e = cudaMalloc((void**)&d_randDouble,sizeof(double)*1000);
	e = cudaMemcpy(d_randDouble,randDouble,sizeof(double)*1000,cudaMemcpyHostToDevice);
	int capacities[4] = {30000,30000,30000,30000};
	int *d_capacities;
	e = cudaMalloc((void**)&d_capacities,sizeof(int)*depotNum);
	e = cudaMemcpy(d_capacities,capacities,sizeof(int)*depotNum,cudaMemcpyHostToDevice);

	simulatedAnnealingKernel<<<1,depotNum>>>(d_r,d_costs,solutionLen,d_demand,d_dis,nodeNum,d_capacities,d_randInt,d_randDouble,100000,0.001);
	
	e = cudaMemcpy(r,d_r,sizeof(int)*depotNum*solutionLen,cudaMemcpyDeviceToHost);
	e = cudaMemcpy(costs,d_costs,sizeof(double)*depotNum,cudaMemcpyDeviceToHost);

	cudaFree(d_r);
	cudaFree(d_costs);
	cudaFree(d_demand);
	cudaFree(d_dis);
	cudaFree(d_capacities);
	cudaFree(d_randDouble);
	cudaFree(d_randInt);
  
 return 0;
}



 