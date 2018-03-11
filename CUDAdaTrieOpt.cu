/********************************************************************
*@version-0.1 
*@author Liyuqian-����ǰ yuqianfly@gmail.com 
*���пƼ���ѧ�����ѧԺ ������ֲ�ʽ����ʵ����
*ע��: �����пƼ���ѧ�����ѧԺ������ֲ�ʽ�����⣬
*�κθ��ˡ��Ŷӡ��о��ṹ����ҵ��λ�Ȳ��ܶԱ��㷨����ר���������׫д
*���㷨�����ġ�
*�κθ��ˡ��Ŷӡ��о��ṹ����ҵ��λ�����ԶԱ��㷨����ʹ�á��޸ġ���չ��������
*ʹ�ñ��㷨������ɵ���ʧ��������ʹ�������и���
* 
* ʹ����ʾ��
*     1�����ʵ���ϸ����û�й���������������������ϵ
*     2������븽���ʵ���Ϣ�������к�ǿ�����ϵ�ԣ��κβ���ȷ�޸Ķ����ܵ���
* �ִ��쳣��
*     3��ʹ�ñ���������У���������ʧ������һ�Ų�����
*     4������������ǰ����Ҫ�㹻�Ķ�ջ�ռ䣬����10240000bytes
*     5���Ż��汾�� ���Ż��汾���ڱ���ʱ��ѡ��һ�����У���֧��ͬʱ����
*     6�����ִַʿ���ѡ���Ӧ��ͬ�����Ŀ¼��
*     7������δ�����������⣬����������ϵ��
*********************************************************************/
#include <stdio.h>
#include <stdlib.h>
#include <cutil_inline.h>
#include <cutil.h>
#include <string.h>
#include <locale.h>

#include "loadDocs.h"
#include <cuda_runtime.h>
#include "InitDictionary.h"

#define WORD_SIZE  30
#define WWORD_NUM   15

#ifndef __GLOBALVAR__
#define __GLOBALVAR__

texture<unsigned int, 1, cudaReadModeElementType> rTBase; 
texture<     int, 1, cudaReadModeElementType> rTCheck; 
texture<unsigned char, 1, cudaReadModeElementType> rTStatus;
texture<unsigned int, 1, cudaReadModeElementType> rTCharsHash;

unsigned char * d_status;
int  * d_check;
unsigned int  * d_base;
unsigned int  * d_charsHash;

#endif
#if __DEVICE_EMULATION__
bool InitCUDA(void){return true;}
#else
bool InitCUDA(void)
{
	int count = 0;
	int i = 0;

	cudaGetDeviceCount(&count);
	if(count == 0) {
		fprintf(stderr, "There is no device.\n");
		return false;
	}

	for(i = 0; i < count; i++) {
		cudaDeviceProp prop;
		if(cudaGetDeviceProperties(&prop, i) == cudaSuccess) {
			if(prop.major >= 1) {
				break;
			}
		}
	}
	if(i == count) {
		fprintf(stderr, "There is no device supporting CUDA.\n");
		return false;
	}
	cudaSetDevice(i);

	printf("CUDA initialized.\n");
	return true;
}
#endif

#ifndef __INITCUDADATRIE__
#define __INITCUDADATRIE__

/**initial the global Variable method.*/
void loadAndBlendTrie(int *h_check,
		unsigned int *h_base,		
		unsigned char *h_status,
		unsigned int *h_charsHash,
		unsigned int h_baseSize,
		unsigned int h_charHashSize){ 

    unsigned int baseMemSize=sizeof(unsigned int)*h_baseSize;
	unsigned int checkMemSize=sizeof(int)*h_baseSize;
	unsigned int statusMemSize=sizeof(unsigned char)*h_baseSize;

	//global base
    CUDA_SAFE_CALL(cudaMalloc( (void**)&d_base,baseMemSize));
	CUDA_SAFE_CALL(cudaMemset(d_base,0,baseMemSize));
	CUDA_SAFE_CALL(cudaMemcpy(d_base,h_base,baseMemSize,cudaMemcpyHostToDevice));
    
	//global check
    CUDA_SAFE_CALL(cudaMalloc( (void**)&d_check,checkMemSize));
	CUDA_SAFE_CALL(cudaMemset(d_check,0,checkMemSize));
	CUDA_SAFE_CALL( cudaMemcpy(d_check,h_check,checkMemSize,cudaMemcpyHostToDevice));

    //global status
    CUDA_SAFE_CALL(cudaMalloc( (void**)&d_status,statusMemSize));
	CUDA_SAFE_CALL(cudaMemset(d_status,0,statusMemSize));
	CUDA_SAFE_CALL( cudaMemcpy(d_status,h_status,statusMemSize,cudaMemcpyHostToDevice));

    //global charsHash
	CUDA_SAFE_CALL(cudaMalloc( (void**)&d_charsHash,sizeof(unsigned int)*(h_charHashSize)));
    CUDA_SAFE_CALL(cudaMemset(d_charsHash,'\0',sizeof(unsigned int)*(h_charHashSize)));		
	CUDA_SAFE_CALL(cudaMemcpy(d_charsHash,h_charsHash,sizeof(unsigned int)*(h_charHashSize),cudaMemcpyHostToDevice));

    //blend array
	cutilSafeCall(cudaBindTexture(0, rTBase, d_base)); 
    cutilSafeCall(cudaBindTexture(0, rTCheck, d_check ));
    cutilSafeCall(cudaBindTexture(0, rTStatus, d_status)); 
    cutilSafeCall(cudaBindTexture(0, rTCharsHash, d_charsHash ));
    
}

//texture blend
bool initCUDAdatrieOpt(){
    
	 int *h_check;
     unsigned int *h_base;	         
     unsigned char *h_status; 
	 unsigned int  *h_charsHash; 

	 InitDictionary initDic;	
     h_base = initDic.base;
	 h_check = initDic.check;
	 h_status = initDic.status;     //��λ����	
	 h_charsHash = initDic.charsHash;
     loadAndBlendTrie(h_check,h_base,h_status,h_charsHash,318608,65535);
	 
	 free(h_check);
     free(h_base);		
	 free(h_status);
     free(h_charsHash);
	 
	 return true;
}

void deleteTrie(){

	cudaUnbindTexture(rTBase); 
    cudaUnbindTexture(rTCheck);
	cudaUnbindTexture(rTStatus); 
    cudaUnbindTexture(rTCharsHash);
	
    cutilSafeCall(cudaFree(d_base));
    cutilSafeCall(cudaFree(d_check));
	cutilSafeCall(cudaFree(d_status));
	cutilSafeCall(cudaFree(d_charsHash));
}
#endif
/************************************************************************/
/* ���ִַ�ʵ��                                                              */
/************************************************************************/
/**����ȫƥ��ִ�*/
__device__ void tGetAllWords(unsigned short *w_chars,int posFrom,int posTo,unsigned short *output){   
	int outputIndex=0;
	int t=0,i=posFrom,start=posFrom,end=0,charHashCode=0;
	unsigned char stats='0';
 		
    int  baseValue = 0;
    int  checkValue = 0;
	for (; i <posTo; i++) {
     	end++;
		charHashCode = tex1Dfetch(rTCharsHash,w_chars[i]);
        if( charHashCode<1 ) stats='0';
		else{
		    checkValue=baseValue;
		    baseValue = tex1Dfetch(rTBase,checkValue) + charHashCode;
		    if (tex1Dfetch(rTCheck,baseValue) == checkValue || tex1Dfetch(rTCheck,baseValue) == -1)
			    stats= tex1Dfetch(rTStatus,baseValue);
		    else
			    stats='0';
		}

		switch (stats) {
			case '0':	
				i = start;
				start++;				
				end = 0;
				baseValue = 0;
				break;

			case '2':
				for(t=0;t<end;t++){
					output[outputIndex++]=w_chars[t+start];
				}
                output[outputIndex++]=49;
				break;
			case '3':
				for(t=0;t<end;t++){
					output[outputIndex++]=w_chars[t+start];					    
			    }                
				 output[outputIndex++]=49;
				 i = start;
				 start++;
				 end = 0;
				 baseValue = 0;				
				 break;
			}//end of switch		
	}//end of for			
}


/**�������ƥ��ִ�*/
__device__ void tMaxFrontWords(unsigned short * w_chars,int posFrom,int posTo,unsigned short * output) {
	int outputIndex=0;

	int t=0,i=posFrom,start=posFrom,end=0,charHashCode=0;
	unsigned char stats='0';
 		
    int  tempEnd = 0;
    int  baseValue = 0;
    int  checkValue = 0;
    bool hasEnd = false;
    int wlen=posTo-posFrom;
	for(;i<posTo;i++){
    	end++;
		charHashCode = tex1Dfetch(rTCharsHash,w_chars[i]);
		if( charHashCode<1 ) stats='0';
		else{
             checkValue=baseValue;
		     baseValue = tex1Dfetch(rTBase,checkValue) + charHashCode;
		     if (tex1Dfetch(rTCheck,baseValue) == checkValue || tex1Dfetch(rTCheck,baseValue) == -1)
			    stats= tex1Dfetch(rTStatus,baseValue);
		     else
			    stats='0';
		}

		switch (stats) {
		case '0':
			if (hasEnd) {
				for(t=0;t<tempEnd;t++){
					output[outputIndex++]=w_chars[t+start];
				}
				output[outputIndex++]=49;
				hasEnd = false;
				baseValue = 0;
				start = start + tempEnd ;
				i = start-1;
				tempEnd = 0;
				end = 0;				
				break;
			} else {
				baseValue = 0;
				tempEnd = 0;
				i = start;
				start++;				
				end = 0;
			}
			break;
		case '2':
			tempEnd = end;
			hasEnd = true;
			break;
		case '3':
			for(t=0;t<end;t++){
				output[outputIndex++]=w_chars[t+start];			
			}
			output[outputIndex++]=49;//�����ַ�1           		
			hasEnd = false;
			baseValue = 0;
			tempEnd = 0;
			start = i ;
			end = 0;				
			break;
		}
		if (i == wlen - 1) {
			if (hasEnd) {
				for(t=0;t<tempEnd;t++){
					output[outputIndex++]=w_chars[t+start];
				}
				output[outputIndex++]=49;	
				hasEnd = false;
				baseValue = 0;
				start = start + tempEnd;
				i = start-1;
				tempEnd = 0;
				end = 0;
				break;
					
			}
		}
	}
}

/**������Сƥ��ִ�*/
__device__ void tMinFrontWords(unsigned short * w_chars,int posFrom,int posTo,unsigned short * output){
  	
    int outputIndex=0;
	int t=0,i=posFrom,start=posFrom,end=0,charHashCode=0;
	unsigned char stats='0';
    int  baseValue = 0;
    int  checkValue = 0;

	for (; i < posTo; i++) {
		end++;
		charHashCode = tex1Dfetch(rTCharsHash,w_chars[i]);
        if( charHashCode<1 ) stats='0';
		else{
        checkValue=baseValue;
		baseValue = tex1Dfetch(rTBase,checkValue) + charHashCode;
		if (tex1Dfetch(rTCheck,baseValue) == checkValue || tex1Dfetch(rTCheck,baseValue) == -1)
			stats= tex1Dfetch(rTStatus,baseValue);
		else
			stats='0';
		}
		switch (stats) {
			case '0':
				baseValue = 0;
				i = start;
				start++;
				end = 0;
				break;
			case '2':
				for(t=0;t<end;t++)	{
					output[outputIndex++]=w_chars[t+start];
				}
				output[outputIndex++]=49;
				baseValue = 0;
				start = i+1;
				end = 0;
				break;
			case '3':
				for(t=0;t<end;t++){
					output[outputIndex++]=w_chars[t+start];
				}
				output[outputIndex++]=49;
				baseValue = 0;
				start = i+1;
				end = 0;
				break;
			}
		}
}

/**�ں���ں���
* ���ܣ����������ĵ��ִ�
* �ĵ����߳���ƽ�����֣�ÿ���ĵ���Ӧһ��block
*/
__global__  void tBatchSearchKernel(HostDocs * inputDocs,HostDocsTotalTokens *outputTokens){ 	
	int bid=blockIdx.x; //��ȫ��id
	int tid=blockIdx.x*blockDim.x+threadIdx.x;//�߳�ȫ��id
	int docsize=inputDocs->DocStreamSize[bid];//���Ӧ�ĵ���С
	int average=docsize/blockDim.x;//ÿ���߳�����
	int start=threadIdx.x*average;//�����˵�
	int end=start+average;//�������˵�
	//tGetAllWords(inputDocs->DocStream[bid],start,end,outputTokens->ThreadsTokens[tid]);
    //tMaxFrontWords(inputDocs->DocStream[bid],start,end,outputTokens->ThreadsTokens[tid]);
    tMinFrontWords(inputDocs->DocStream[bid],start,end,outputTokens->ThreadsTokens[tid]);
}

/**
����汾���ܣ�
���ݼ��ص��ĵ�������������Ӧ��block����ÿ��block����TREAD_PER_BLOCK�߳�
�ִʽ������thread��λ���棬�� block_num* TREAD_PER_BLOCK ������Ԫ�أ�
ÿ��Ԫ�س���MAX_TOKEN_PER��THREAD==100 ��ÿ���̷ִ߳ʽ�����100��������
*/
void runCUDADATrieOpt(char * inputFold,char * outputFold){  
	// make double trie
	if(initCUDAdatrieOpt())
	   printf("InitCUDADAtrie success.\n\n");
    else
	   printf("*** initCUDADATrie failed!\n\n");
	
	//���ļ���inputFold���������ĵ���������������Ҫ������������DOC_BATCH_SIZE==96
	 HostDocs *hdocs = loadBatchDocs(inputFold);
     printHostDocs("docs",hdocs);

	 printf("\nCopy docs to GPU...\n");
	 HostDocs *ddocs;
	 unsigned short **CPU_ARRAY;
	 CPU_ARRAY =(unsigned short **)malloc(sizeof(unsigned short*)*DOC_BATCH_SIZE);
	 memset(CPU_ARRAY,0,sizeof(unsigned short*)*DOC_BATCH_SIZE);

	 int docSize=0,docsNum=hdocs->DocCount;
	 for(int i=0;i<docsNum;i++){
		 docSize=hdocs->DocStreamSize[i];
         cutilSafeCall( cudaMalloc((void **)&CPU_ARRAY[i],sizeof(unsigned short)*docSize));
         cutilSafeCall( cudaMemset(CPU_ARRAY[i],0,sizeof(unsigned short)*(docSize)));
         cutilSafeCall( cudaMemcpy(CPU_ARRAY[i],hdocs->DocStream[i],sizeof(unsigned short)*docSize,cudaMemcpyHostToDevice));
	 }   
	cutilSafeCall(cudaMalloc( (void**)&ddocs,sizeof(HostDocs)));
	cutilSafeCall(cudaMemcpy(ddocs->DocStream,CPU_ARRAY,sizeof(unsigned short*)*DOC_BATCH_SIZE,cudaMemcpyHostToDevice));
	cutilSafeCall(cudaMemcpy(ddocs->DocStreamSize,hdocs->DocStreamSize,sizeof(unsigned short)*DOC_BATCH_SIZE,cudaMemcpyHostToDevice));
	printf("End of copy\n\n");
     
	//printHostDocs("d_docs test",bdocs); 

	//cpu�˽����ں�������
	HostDocsTotalTokens *hDocAllTokens;
	int tokensTotalMemSize=TOTAL_THREADS_NUM*MAX_TOKEN_PER��THREAD;//128*96*100
    hDocAllTokens=(HostDocsTotalTokens*)malloc(sizeof(HostDocsTotalTokens));
	hDocAllTokens->threadsNum=0;
	memset(hDocAllTokens->ThreadsTokens,0,sizeof(unsigned short)*tokensTotalMemSize);
	 
	 //�ں�������
	HostDocsTotalTokens *dDocAllTokens;
    CUDA_SAFE_CALL(cudaMalloc( (void**)&dDocAllTokens,sizeof(HostDocsTotalTokens)));
	int tNum=docsNum*TREAD_PER_BLOCK;//ȫ���߳���Ŀ2*128
	cutilSafeCall(cudaMemcpy( &dDocAllTokens->threadsNum,&tNum,sizeof(unsigned short),cudaMemcpyHostToDevice));
	cutilSafeCall(cudaMemset( dDocAllTokens->ThreadsTokens,0,sizeof(unsigned short)*tokensTotalMemSize));
	
	int blockNum=docsNum;//�����߳̿���Ŀ
	int threadsPerBlock=TREAD_PER_BLOCK;//ÿ���߳̿�������̸߳���
    
	dim3 dimBlock(threadsPerBlock,1,1);
	dim3 dimGrid(blockNum,1);
    printf("start kernel...\n");
    unsigned int timer = 0;
    cutilCheckError( cutCreateTimer( &timer));
    cutilCheckError( cutStartTimer( timer));
	
	tBatchSearchKernel<<<dimGrid,dimBlock>>>(ddocs,dDocAllTokens); 
    //testLoad<<<1,1>>>(ddocs,writeDoc);
	cutilCheckMsg("Kernel execution failed\n");	
	cudaThreadSynchronize();
	
    cutilCheckError( cutStopTimer( timer));
    printf("Kernel processing time: %f (ms)\n", cutGetTimerValue( timer));
    cutilCheckError( cutDeleteTimer( timer));
    printf("end of kernel\n");

	cutilSafeCall(cudaMemcpy(hDocAllTokens,dDocAllTokens,sizeof(HostDocsTotalTokens),cudaMemcpyDeviceToHost));
	writeDocsTotalTokens("keneal docs total tokens: minWords",outputFold,hDocAllTokens);

	//�ͷ���Դ
    free(hdocs);
    free(hDocAllTokens);
	cutilSafeCall(cudaFree(ddocs));
	cutilSafeCall(cudaFree(dDocAllTokens));	
   
	deleteTrie();
}


int main(int argc, char* argv[])
{
	if(!InitCUDA()) {
		return 0;
	} 
   
	char *console="outputFiles/OminWords_log_48p_64t.txt";
    //freopen(console,"w",stdout); //����ض���������ݽ�������out.txt�ļ��� 
    //time_t timep;
    //time (&timep);
	//printf("------------------------\n");
    //printf("%s\n",ctime(&timep));
	char * inputFold="inputFiles/48/";
	char * outputFold="outputFiles/OminWords_48p_64t.txt";
    runCUDADATrieOpt(inputFold,outputFold);

	//time (&timep);	
	//printf("%s\n",ctime(&timep));
    //printf("------------------------\n");
    //fclose(stdout);//�ر��ļ� 

	CUT_EXIT(argc, argv);   
	return 0;
}
