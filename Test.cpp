#include<iostream>
#include<fstream>

using namespace std;
#define SIZE 10240
#define MAXVN 10
void simulatedAnnealingKernel1(int i,int *route,
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
										 const double cr);
int f(int n){
   if( n == 0)
	   return 0;
   if( n<10)
	   return 1;
   else{
	   int counter = 0;
	   int temp = n;
	   while( temp>0){
		   if(temp%10 == 1)
	          counter ++;
		   temp = temp /10;
	   }
	   return f(n-1)+counter;
   }
}

int f2(int n){
	int bit[100] ={0};
	int len = 0;
	int temp = n;
	int counter = 0;
	while(temp>0){
	   bit[len++] = temp%10;
	   temp = temp /10;
	}
	for(int i =0; i<len; i++){
		int tempCounter = 0;
	    for(int j = len -1; j>=0; j--)
		{
			if(i != j){
			  tempCounter = tempCounter*10+bit[j];
			}
		}
		if(bit[i]<1)
			counter += tempCounter;
		else
			counter += tempCounter+1;
	}
	return counter;
}

int main1(){
	
	/*int i=0;
	for(; i<20000000; i++){
	  int temp = f2(i);
	  if(i == temp){
	    printf("f2(%d)=%d\n",i,temp);
	  }
	}*/

	//printf("f(%d)=%d  ",1000000,f(1000000));
	/*printf("f2(%d)=%d\n",1000000,f2(1000000));*/

	const int nodeNum = 97;
	const int depotNum = 9;
	const int vehicleNum = 1;
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
	int capacities[9]={200};
	for(int i =0;i<depotNum;i++){
		simulatedAnnealingKernel1(i,r,costs,solutionLen,demand,dis,nodeNum,200,1,randInt,randDouble,10000,0.001);
	}
  
	cout<<"\nok"<<endl;

 return 0;
}

 void simulatedAnnealingKernel1(int x,int *route,
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
	int depot = x;
	if (x ==5)
	{
	   std::cout<<"llll\n";
	}
	int *bestSolution = route + (depot)*solutionLen;
	int solutionArray[SIZE];

	//ÿ���̷߳���3*solutonLen*4 Byte ��С�Ĺ����ڴ�
	 
	//�����ڴ����  
	int *solution = &solutionArray[x*(solutionLen*2+6*MAXVN)]; //solutionLen

    int *curSolution = (int *)&solution[solutionLen];  //solutionLen
	double *dice =(double*)&curSolution[solutionLen];
	int *cusIndex = (int*)&dice[1];
	int *range = (int*)&cusIndex[1];
	int *v = (int*)&range[1];
	int *improvedTryCounter = (int*)&v[1];
    int *demandCounter=(int*)&improvedTryCounter[MAXVN]; //4
	int *routeStart=(int*)&demandCounter[MAXVN];  //6
	double *acc = (double*)&routeStart[MAXVN+1];    //5


	

	

	//�Ĵ�������
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
	


	//�������
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
	
	improvedTryCounter[0] =1;
	improvedTryCounter[1]=1;
	
	while(temp > 0.01){
	     //ѡ�����
	    *dice =randDouble[(nextRand+x*20)%1000];
		nextRand =(nextRand+1)%1000;
		if(*dice <= 0.1+0.8*(improvedTryCounter[0]/(double)(improvedTryCounter[0]+improvedTryCounter[1]))){
			//ѡ�����1
			strategy = 0;
		    *r1 = 1+randInt[(nextRand+x*20)%1000]%(len-2);
			nextRand = (++nextRand)%1000;
		    *r2 = 1+randInt[(nextRand+x*20)%1000]%(len-2);
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

			*dice =randDouble[(nextRand+x*20)%1000];
			nextRand = (++nextRand)%1000;
			*v = 0;
			while(*dice>acc[*v]) (*v)++; //�ҵ���Ӧ�ĳ�Ϊv
			//��v�г�ȡһ���ͻ�Ȼ������뵽�����ĳ����ʵ�·��λ�� ���ͻ���λ��Ӧ����routeStart[*v]��routeStart[v+1]֮��
		    *range = routeStart[*v+1]-routeStart[*v]-1;
			if(*range ==0)
				continue;
		    *cusIndex = routeStart[*v]+1+randInt[(nextRand+x*20)%1000]%*range;
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

			*dice =randDouble[(nextRand+x*20)%1000];
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
		double newDis = 0;
	    for(i =1; i<len-1;i++){
		 int pre = solution[i];
		 int cur = solution[i+1];
		 newDis += distances[(pre-1)*nodeNum+cur-1];
	    }
		//�ж��½��Ƿ���������Լ��
		for(i=0; i<vNum; i++){
		   if(demandCounter[i] > capacities){
		      newDis += capacities;
		   }
		}

		//����½�ȵ�ǰ����ţ��滻
		if(newDis < dis){
			for(i = 0;i< len; i++){
				curSolution[i] = solution[i];
			}
			dis = newDis;
			improvedTryCounter[strategy] ++;
			//��������Ž���ţ��滻���Ž�
			if( newDis < costs[depot]){
				for(i =0; i< len; i++){
				   bestSolution[i] = solution[i];
				}
				costs[depot] = newDis;
			}
		}else{
			//�����Ը��� exp((dis - newDis)/temp)�滻
			*dice =randDouble[(nextRand+x*20)%1000];
			nextRand = (++nextRand)%1000;
			if(*dice < exp((dis - newDis)/temp)){
			     for(i = 0;i< len; i++){
				   curSolution[i] = solution[i];
			     }
			     dis = newDis;
			}
		}
		temp *=1 - cr;
	}
}