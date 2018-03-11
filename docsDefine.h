/**
* Head file define some of the core struct
* @auther LiYuqian IDC HUST WuHan
* @email  yuqianfly@gmail.com
*/
#ifndef __PATCHDOCS__
#define __PATHCDOCS__

#define DOC_BATCH_SIZE     128
#define TREAD_PER_BLOCK    64
#define TOTAL_THREADS_NUM  16384//DOC_BATCH_SIZE*TREAD_PER_BLOCK

#define MAX_DOC_SIZE        12288    //  12K
#define MAX_DOC_SIZE_BATCH  960000   // about 960k
#define MAX_TOKEN_PER��THREAD 384 //ÿ���̷ֳ߳��Ĵ�ռ�ռ�,allwordʱ�ռ�Ҫ��

//���������ĵ�
struct HostDocs{	
   unsigned DocCount;
   unsigned short DocStreamSize[DOC_BATCH_SIZE];//0--docCount,1--total size�ճ�����
   unsigned short *DocStream[DOC_BATCH_SIZE];  //�ĵ���ָ��  
};

//���̱߳���
struct HostDocsTotalTokens{
   unsigned short  threadsNum;
   unsigned short  ThreadsTokens[TOTAL_THREADS_NUM][MAX_TOKEN_PER��THREAD];//ÿ���߳�һ�������
};

#endif