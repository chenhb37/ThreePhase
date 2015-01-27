//verion 1
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
										 const int capacities,
										 const int vNum,
										 const int *randInt,
										 const double *randDouble,
										 const double tempParam,
										 const double cr)
{ 
	int depot = threadIdx.x;
	int *bestSolution = route + (depot)*solutionLen;
	__shared__ int solutionArray[SIZE];

	//ÿ���̷߳���3*solutonLen*4 Byte ��С�Ĺ����ڴ�
	 
	//�����ڴ����  
	int *solution = &solutionArray[threadIdx.x*(solutionLen*2+7*MAXVN)]; //solutionLen

    int *curSolution = (int *)&solution[solutionLen];  //solutionLen
	double *dice =(double*)&curSolution[solutionLen];
	double *dis = (double*)&dice[1];
	double *newDis = (double*)&dis[1];
	int *cusIndex = (int*)&newDis[1];
	int *range = (int*)&cusIndex[1];
	int *v = (int*)&range[1];
	int *improvedTryCounter = (int*)&v[1];
    int *demandCounter=(int*)&improvedTryCounter[MAXVN]; //4
	int *routeStart=(int*)&demandCounter[MAXVN];  //6
	double *acc = (double*)&routeStart[MAXVN+1];    //5
	int *r1=v;
	int *r2=range;
	int *inter =cusIndex;

	//�Ĵ�������
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
	int nextRand = 0;
	int strategy = 0;
	double temp = tempParam;//cr = 0.001;//tempPara;
	


	//�������
    *dis = 0;
	int len = 1;
	for(int i =1; bestSolution[i]!=0; i++){
		  pre = bestSolution[i-1];
		  cur = bestSolution[i];
		  *dis += distances[(pre-1)*nodeNum+cur-1];
		  len ++;
	}

	for(int i =0; i< len; i++){
		solution[i] = bestSolution[i];
	    curSolution[i] = bestSolution[i];
     }
	//����Ƿ���
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
	//�ж��½��Ƿ���������Լ��
		for(i=0; i<vNum; i++){
		   if(demandCounter[i] > capacities){
		      *dis += capacities;
		   }
		}


	costs[depot] = *dis;
	
	improvedTryCounter[0] =1;
	improvedTryCounter[1]=1;
	
	while(temp > 0.01){
	     //ѡ�����
	    *dice =randDouble[(nextRand+threadIdx.x*20)%1000];
		nextRand =(nextRand+1)%1000;
		if(*dice <= 0.1+0.8*(improvedTryCounter[0]/(double)(improvedTryCounter[0]+improvedTryCounter[1]))){
			//ѡ�����1
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
		else{
		    //ѡ�����2
			//ͳ�Ƹ��������ĸ��أ����ݳ����ĸ��ص���
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
			for(i = 1; i< vNum; i++){
			     acc[i] = acc[i-1]+demandCounter[i]/(demandSum+0.1);
			}
			acc[i-1] = 1;

			*dice =randDouble[(nextRand+threadIdx.x*20)%1000];
			nextRand = (++nextRand)%1000;
			*v = 0;
			while(*dice>acc[*v]) (*v)++; //�ҵ���Ӧ�ĳ�Ϊv
			//��v�г�ȡһ���ͻ�Ȼ������뵽�����ĳ����ʵ�·��λ�� ���ͻ���λ��Ӧ����routeStart[*v]��routeStart[v+1]֮��
		    *range = routeStart[*v+1]-routeStart[*v]-1;
			if(*range ==0)
				continue;
		    *cusIndex = routeStart[*v]+1+randInt[(nextRand+threadIdx.x*20)%1000]%*range;
			nextRand = (++nextRand)%1000;


            //������ѡ���ؽ�С�ĳ�
		    maxDemand = demandCounter[maxDemandIndex];
			acc[0] = (maxDemand - demandCounter[0])/(vNum*maxDemand - demandSum+0.1);
			for(i =1; i< vNum; i++){
			    acc[i] = acc[i-1]+(maxDemand - demandCounter[i])/(vNum*maxDemand - demandSum+0.1);
			}
			acc[i-1] = 1;

			//����demandCounter
			demandCounter[*v] -= demands[solution[*cusIndex]-1];

			*dice =randDouble[(nextRand+threadIdx.x*20)%1000];
			nextRand = (++nextRand)%1000;

			*v = 0;
			while(*dice>acc[*v]) (*v)++; //�ҵ���Ӧ�ĳ�Ϊ*v �䷶ΧΪrouteStart[*v]��routeStart[*v+1]

			//����demandCounter
			demandCounter[*v] += demands[solution[*cusIndex]-1];

		    minCost = 100000;
		    insertPoint = 0;
		    cus = solution[*cusIndex];
			cost = 0;
			//��*cusIndex��Ӧ�Ŀͻ����뵽����*v��Ӧ��·���к��ʵ�λ��
            for(i = routeStart[*v]; i<routeStart[*v+1]; i++){
				   cost = distances[(cus-1)*nodeNum+solution[i]-1]+
					      distances[(cus-1)*nodeNum+solution[i+1]-1]-
						  distances[(solution[i]-1)*nodeNum+solution[i+1]-1];
				   if(cost < minCost){
					   minCost =cost;
					   insertPoint = i;
				   }
			}

		    //��cus��*cusIndex��λ�ò��뵽insertPoint��λ��
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

		//�����½���ܾ���
	   *newDis = 0;
	    for(i =1; i<len-1;i++){
		 pre = solution[i];
		 cur = solution[i+1];
		*newDis += distances[(pre-1)*nodeNum+cur-1];
	    }
		//�ж��½��Ƿ���������Լ��
		for(i=0; i<vNum; i++){
		   if(demandCounter[i] > capacities){
		      *newDis += capacities;
		   }
		}

		//����½�ȵ�ǰ����ţ��滻
		if(*newDis < *dis){
			for(i = 0;i< len; i++){
				curSolution[i] = solution[i];
			}
			*dis = *newDis;
			improvedTryCounter[strategy] ++;
			//��������Ž���ţ��滻���Ž�
			if( *newDis < costs[depot]){
				for(i =0; i< len; i++){
				   bestSolution[i] = solution[i];
				}
				costs[depot] = *newDis;
			}
		}else{
			//�����Ը��� exp((dis - newDis)/temp)�滻
			*dice =randDouble[(nextRand+threadIdx.x*20)%1000];
			nextRand = (++nextRand)%1000;
			if(*dice < exp((*dis - *newDis)/temp)){
			     for(i = 0;i< len; i++){
				   curSolution[i] = solution[i];
			     }
			     *dis = *newDis;
			}else{
				//����������½⣬��ԭ��
			    for(i = 0;i< len; i++){
				   solution[i] = curSolution[i];
			    }
			}
		}
		temp *=1 - cr;
		__syncthreads(); 
	}
}


int main(){
	const int nodeNum = 52;
	const int depotNum = 2;
	const int vehicleNum = 6;
	const int solutionLen = nodeNum - depotNum + vehicleNum + 1;
	int r[depotNum*solutionLen] = {0};
	int demand[nodeNum] = {0};
	double dis[nodeNum*nodeNum]={0};
	double randDouble[1000] = {0};
	int randInt[1000] ={0};
	int capacities = 5000;
	int vNum =6;


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
	
	simulatedAnnealingKernel<<<1,depotNum>>>(d_r,d_costs,solutionLen,d_demand,d_dis,nodeNum,capacities,vNum,d_randInt,d_randDouble,100000,0.001);
	
	e = cudaMemcpy(r,d_r,sizeof(int)*depotNum*solutionLen,cudaMemcpyDeviceToHost);
	e = cudaMemcpy(costs,d_costs,sizeof(double)*depotNum,cudaMemcpyDeviceToHost);

	cudaFree(d_r);
	cudaFree(d_costs);
	cudaFree(d_demand);
	cudaFree(d_dis);
	cudaFree(d_randDouble);
	cudaFree(d_randInt);
  
 return 0;
}



 