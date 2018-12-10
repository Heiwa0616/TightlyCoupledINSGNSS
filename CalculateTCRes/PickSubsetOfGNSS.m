function [ EliminationMask,PDOP, RunningTime] = PickSubsetOfGNSS( method,IntendedSatNum,RecPosi,SatPosi )
%��������Ϊѡ�ǵĵڶ������ڣ���һ������Ϊ�޳��쳣���ǣ����޳���������ʹ��ʣ������������Ҫ��
%���룺
% method            ѡ�Ƿ�����ʶ
%                       'RedundancyMatrix' �ο����ף�Park C W, How J P. Method and apparatus for selecting optimal satelittes in global positioning system: U.S. Patent 6,727,850[P]. 2004-4-27.
%                       'Optimal' ��������������ϣ�����СPDOP
% IntendedSatNum    ϣ�����������Ǹ���
% RecPosi           �����GNSS���ջ�����λ��
% SatPosi           ����λ��ECEF��ÿ��Ϊһ�����ǵ�λ�ã�����ΪXYZ����λ��m
% �����
% EliminationMask   ��������0��ʾ������1��ʾ�޳�������������SatPosi�����ж�Ӧ
% PDOP              ���Ǻ��PDOPֵ
% RunningTime       ѡ�ǳ�������ʱ��(����PDOP����)
tic %��ʼ��ʱ
[SatNum,~]=size(SatPosi);
EliminationMask=false(SatNum,1);
if strcmpi(method, 'RedundancyMatrix')
    LOS=SatPosi-ones(SatNum,1)*RecPosi';
    MatrixD=eye(SatNum);
    for SatIndexRow=2:SatNum
        for SatIndexCol=1:SatIndexRow-1
            MatrixD(SatIndexRow,SatIndexCol)=dot(LOS(SatIndexRow,1:3),LOS(SatIndexCol,1:3))/...
                norm(LOS(SatIndexRow,1:3))/norm(LOS(SatIndexCol,1:3));
        end
    end
    MatrixRedundancy=MatrixD.*MatrixD;
    MatrixRedundancy=MatrixRedundancy+tril(MatrixRedundancy,-1)';
    while sum(EliminationMask)<SatNum-IntendedSatNum
        Redundancy=sum(MatrixRedundancy);
        [~,EliminationFlag]=max(Redundancy);
        EliminationMask(EliminationFlag)=true;
        MatrixRedundancy(EliminationFlag,:)=0;
        MatrixRedundancy(:,EliminationFlag)=0;
    end
elseif strcmpi(method, 'Optimal')
    AllCase=nchoosek(1:SatNum,IntendedSatNum);
    PDOPAllCase=zeros(length(AllCase),1);
    for CaseIndex=1:length(AllCase)
        EliminationMask=true(SatNum,1);%reset
        EliminationMask(AllCase(CaseIndex,:))=false;
        LOS=ones(sum(~EliminationMask),1)*RecPosi'-SatPosi(~EliminationMask,1:3);
        for i=1:sum(~EliminationMask)
            LOS(i,1:3)=LOS(i,1:3)/norm(LOS(i,1:3));
        end
        PDOPAllCase(CaseIndex)=sqrt(trace(inv(LOS'*LOS)));
    end
    [PDOP,IndexMinPDOP]=min(PDOPAllCase);
    EliminationMask=true(SatNum,1);%reset
    EliminationMask(AllCase(IndexMinPDOP,:))=false;
    RunningTime=toc;
    return
else
    disp(['GNSS ѡ���㷨:' method 'δ����'])
end
RunningTime=toc;
LOS=ones(sum(~EliminationMask),1)*RecPosi'-SatPosi(~EliminationMask,1:3);
for i=1:sum(~EliminationMask)
    LOS(i,1:3)=LOS(i,1:3)/norm(LOS(i,1:3));
end
PDOP=sqrt(trace(inv(LOS'*LOS)));
return


