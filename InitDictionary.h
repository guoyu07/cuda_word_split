#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
/**
* @auther LiYuqian IDC HUST WuHan
* @email  yuqianfly@gmail.com
*/

/**notice when run these program must need large stack */
#ifndef __DICTIONARY__
#define __DICTIONARY__
struct InitDictionary{
    public:
	// base: ����������ŵ��ʵ�ת��..��ʵ����һ��DFAת������ 
	unsigned int *base; //ʵ��240094������,�ռ���Ч�� 240094/318608=0.75357
	
	// check: ����������֤����洢������һ��״̬��λ��	 
    int *check;	
	
	// status: �����ж�һ�����ʵ�״̬ 1.Ϊ���ɴ�.���ڹ��Ƚ׶� 2.�ɴ�Ҳ�����Ǵ����һ����. 3.�������
	// example: �� 1 �л� 2 �л��� 1 �л����� 3	
	unsigned char *status;
	
	// * charsHash: ���ֱ�������.��4000������ú��ֽ��������±���.
	unsigned int *charsHash; //ʵ��6143 6142/65535=0.093736  
		 
    public:
		   char  haspath[40];
           char arraysPath[40];
           char charEncoding[8];
           bool isInit;
    public:
	       void initArrays();
	       void initCharsHash();
	       void init();
	
InitDictionary(){	
	base=(unsigned int*)malloc(sizeof(unsigned int)*318608);
	memset(base,0,sizeof(unsigned int)*318608);
	check=(int*)malloc(sizeof(int)*318608);
	memset(check,0,sizeof(int)*318608);
    status=(unsigned char*)malloc(sizeof(unsigned char)*318609);
	memset(status,0,sizeof(unsigned char)*318609);
	charsHash=(unsigned int*)malloc(sizeof(unsigned int)*65535);
	memset(charsHash,0,sizeof(unsigned int)*65535);

    strcpy(haspath,"library/charHash.dic");
    strcpy(arraysPath,"library/arrays_modify2.dic");
	strcpy(charEncoding,"GBK");
	isInit = false;
	
	init();
	
  }
};

void InitDictionary::init() {
	if (!isInit) {
	    double start = (double)clock();
		printf("InitCharsHash...\n");	
	    initCharsHash();
		printf("InitArrays...\n");
		initArrays();
			//printf("End of initing\n");
		isInit = true;
		double end=(double)clock();
		printf("�ʵ���������ʱ:%10.4lf ����\n\n",end-start );			
	}
}

//  and arraysPath="library/arrays_modify2.dic" ;
void InitDictionary::initArrays(){	

	FILE *farrayp;
	if((farrayp=fopen(arraysPath,"r"))==NULL){
		printf("Cannot open file: %s!",arraysPath);
        getchar();
        exit(1);
	}
     
    int i=0;
	int num=0,bs_value=0,ck_value=0;
	unsigned char status_value='a';
    for(i=0;i<240094;i++) { 
	    fscanf(farrayp,"%d %d %d %c\n",&num,&bs_value,&ck_value,&status_value);	
		base[num]   = bs_value;
		check[num]  = ck_value;
		status[num] =status_value;		
	}
	status[318608]='\0';

	printf("total line: %d\n",i);
	if(fclose(farrayp)==0)
		printf("file: %s close is success!\n",arraysPath);
	else
		printf("*** !! file: %s close failed\n",arraysPath);

}

	/**
	 * ���ֱ���ʵ�ļ���
	 * һ	19968	2
	 * 19968��Ӧ���� һ��unicode����ֵ����java�к���һ ����һ���ַ� ��c�е��������ַ�
	 * 
	 */

void InitDictionary::initCharsHash(){	
	FILE *fhp;
	if((fhp=fopen(haspath,"r"))==NULL){
		printf("Cannot open file: %s!",haspath);
        getchar();
        exit(1);
	}
      
    unsigned int i=0,j=0,n=0;
    char aword[4];
    for(i=0;i<6143;i++) {   
	     fscanf(fhp,"%s %d %d \n",aword,&j,&n);              	
		 charsHash[j] = n;			    			
	}
	printf("total line: %d\n",i); 
    if(fclose(fhp)==0)
		printf("file��%s close ok!\n",haspath);
	else
		printf("*** !!! file��%s close failed!\n",haspath);
	
}
#endif 
/*
int main(int argc, char *argv[])
{   
	InitDictionary initDic; 	
    return 0;
}
*/