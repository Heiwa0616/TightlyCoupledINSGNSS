%CreatMOD_STA���ɲ�վ���ýṹ��STA
clc
clear
load('ControlNet');
STA.Num=1;%total station number
STA.FixNum=0;% number of fixed stations 
STA.STA(1).Name='BUAAStaticBeiDouPPPRes2017Day320';%Station Name
STA.STA(1).SKD='K';%Station coordinate status, fix or kinemetic
STA.STA(1).Coor=[-2171981.63614967,4386001.44447237,4076182.47907183];
[L_b,lambda_b,h_b,~,~] = ECEF_to_NED(STA.STA(1).Coor',zeros(3,1),eye(3));
STA.STA(1).BLH=[L_b*180/pi,lambda_b*180/pi,h_b];
% STA.STA(1).BLH=[34.207029018 , 117.135303736  ,  45.4034];%Station BLH  latitude(deg) longitude(deg)  height(m) 
STA.STA(1).NEU=[0,0,0];%�������������ο���ı�����λ��
% [STA.STA(1).Coor,~,~]=NED_to_ECEF(STA.STA(1).BLH(1)*pi/180,STA.STA(1).BLH(2)*pi/180,STA.STA(1).BLH(3),zeros(3,1),eye(3));
% STA.STA(1).Coor=STA.STA(1).Coor';%Station Coordination
STA.STA(1).Rotation=[   -sind(STA.STA(1).BLH(1))*cosd(STA.STA(1).BLH(2)),-sind(STA.STA(1).BLH(1))*sind(STA.STA(1).BLH(2)),cosd(STA.STA(1).BLH(1));
                        -sind(STA.STA(1).BLH(2)),cosd(STA.STA(1).BLH(2)),0;
                        cosd(STA.STA(1).BLH(1))*cosd(STA.STA(1).BLH(2)),cosd(STA.STA(1).BLH(1))*sind(STA.STA(1).BLH(2)),sind(STA.STA(1).BLH(1))];
STA.STA(1).Coor=STA.STA(1).Coor+STA.STA(1).NEU*STA.STA(1).Rotation;%������ת�����߲ο���
[L_b,lambda_b,h_b,~,~] = ECEF_to_NED(STA.STA(1).Coor',zeros(3,1),eye(3));
STA.STA(1).BLH=[L_b*180/pi,lambda_b*180/pi,h_b];
MJD=YMDHMS2Mjd(int_year,1,int_doy, 12, 0, 0.d0);
if strcmp(cdattype,'GPT')==1
    [STA.STA(1).Trop.press ,STA.STA(1).Trop.temp, STA.STA(1).Trop.rhumity, STA.STA(1).Trop.undu]...
        = gpt( MJD,STA.STA(1).BLH(1)*pi/180,STA.STA(1).BLH(2)*pi/180,STA.STA(1).BLH(3) );
elseif strcmp(cdattype,'GPT2')==1
    disp('������GPT2��δ��ɣ���ʹ������GPT')
    pause
end
if strcmp(cztd,'SAAS')==1
    [STA.STA(1).Trop.ZHD,STA.STA(1).Trop.ZWD]=ZTD_SAAS(STA.STA(1).Trop.press ,...
        STA.STA(1).Trop.temp, STA.STA(1).Trop.rhumity,STA.STA(1).BLH(1)*pi/180,...
        STA.STA(1).BLH(3));
elseif strcmp(cztd,'EGNOS')==1
    disp('�춥ģ��EGNOS��δ��ɣ���ʹ������SAAS')
    pause    
end
save('MOD_STA_BUAAStaticBeiDouPPPRes2017Day320','STA')



    



