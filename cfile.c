extern void read();
extern void runpro();
extern void clear();
extern void restart();
extern void ppp();
typedef struct Registerimage /*将IP，CS，FLAG放在最后方便实现*/
{
	int DS;
	int ES;
	int SS;
	int DI;
	int SI;
	int BP;
	int SP;
	int AX;
	int BX;
	int CX;
	int DX;
	int IP;
	int CS;
	int FLAG;
}Registerimage;
typedef struct PCB
{
	Registerimage rimg;
	int ID;
	int status;
}PCB;
char* pointer;
char filename[11];
char order[100];
char ans[100];
PCB PCBlist[10];
int proindex=0;
int pronum=0;
int num;
int i,j;
initialPCB(int cs,int ip)
{
	PCBlist[proindex].rimg.DS=cs;
	PCBlist[proindex].rimg.ES=cs;
	PCBlist[proindex].rimg.SS=cs;
	PCBlist[proindex].rimg.DI=0;
	PCBlist[proindex].rimg.SI=0;
	PCBlist[proindex].rimg.BP=0;
	PCBlist[proindex].rimg.SP=ip;
	PCBlist[proindex].rimg.AX=0;
	PCBlist[proindex].rimg.BX=0;
	PCBlist[proindex].rimg.CX=0;
	PCBlist[proindex].rimg.DX=0;
	PCBlist[proindex].rimg.IP=ip;
	PCBlist[proindex].rimg.CS=cs;
	PCBlist[proindex].rimg.FLAG=512; 
	PCBlist[proindex].ID=proindex;
	PCBlist[proindex].status=0;
}
savePCB(int ds,int es,int ss,int di,int si,int bp,
int sp,int ax,int bx,int cx,int dx,int ip,int cs,int flag)
{
	PCBlist[proindex].rimg.DS=ds;
	PCBlist[proindex].rimg.ES=es;
	PCBlist[proindex].rimg.SS=ss;
	PCBlist[proindex].rimg.DI=di;
	PCBlist[proindex].rimg.SI=si;
	PCBlist[proindex].rimg.BP=bp;
	PCBlist[proindex].rimg.SP=sp;
	PCBlist[proindex].rimg.AX=ax;
	PCBlist[proindex].rimg.BX=bx;
	PCBlist[proindex].rimg.CX=cx;
	PCBlist[proindex].rimg.DX=dx;
	PCBlist[proindex].rimg.IP=ip;
	PCBlist[proindex].rimg.CS=cs;
	PCBlist[proindex].rimg.FLAG=flag;
}
int choosepro()
{
	int i=0,j=0;
	for(i=0;i<pronum;i++)
	{
		if(PCBlist[i].status!=2)
			j=1;
	}
	if(j==0) /*表示所有程序都运行完毕了*/
		return 0;
	if(PCBlist[proindex].status!=2)
		PCBlist[proindex].status=0;
	if(proindex>=pronum-1)
		proindex=0;
	else
		proindex++;
	if(PCBlist[proindex].status!=2)
		PCBlist[proindex].status=1;
	return 1;
}
int comparerootrecord()
{
	int i=0,j=0;
	int ans=0;
	pointer=0x5000;
	for(i=0;i<16;i++)
	{
		for(j=0;j<11;j++)
		{
			if(filename[j]!=*pointer)
			{
				pointer-=j;
				break;
			}
			if(j==10)
			{
				pointer+=0x1a;
				pointer-=10;
				ans=(*pointer);
				pointer++;
				ans=ans+(*pointer)*256;
				num=ans;
				return ans;
			}
			pointer++;
		}
		pointer+=32;
	}
	return ans;
}
int find()
{
	int x=0x0fff;
	int y;
	y=num;
	pointer=0x5000;
	y=y*3;
	pointer=pointer+y/2;
	if(*pointer<0)
		num=(*pointer)+256;
	else
		num=(*pointer);
	pointer++;
	if(*pointer<0)
		num+=(*pointer+256)*256;
	else
		num+=(*pointer)*256;
	if(y%2)
	{
		num=num>>4;
	}
	else
	{
		num=num&x;
	}
	return num;
}
int getorder()
{
	i=0;
	j=0;
	for(i=0;i<100;i++)
		order[i]=0;
	read();
	for(i=0;i<100;i++)
		ans[i]=order[i];
	for(i=0;i<100;i++)
	{
		if(order[i]==' '||order[i]==0)
		{
			while(j<8)
			{
				filename[j]=' ';
				j++;
			}
			filename[8]='B';
			filename[9]='I';
			filename[10]='N';
			runpro();
			j=0;
		}
		else
		{
			filename[j]=order[i];
			if(filename[j]>='a'&&filename[j]<='z')
				filename[j]=filename[j]+'A'-'a';
			j++;
		}
		if(j>=9)
			return 0;
		if(order[i]==0)
		{
			break;
		}
	}
	return 1;
}
numtochar(int n)
{
	int i=0,j=0;
	for(i=0;i<100;i++)
		ans[i]=0;
	while(n)
	{
		ans[i]=n%10+'0';
		n=n/10;
		i++;
	}
	for(j=0;j<i/2;j++)
	{
		char t=ans[i-j-1];
		ans[i-j-1]=ans[j];
		ans[j]=t;
	}
}
int ischar(char ch)
{
	if(ch>='a'&&ch<='z')
		return 1;
	if(ch>='A'&&ch<='Z')
		return 2;
	return 0;
}