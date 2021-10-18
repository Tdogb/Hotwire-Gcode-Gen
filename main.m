rootFoil = table2array(readtable("NACA 0014.dat"));
tipFoil = table2array(readtable("NACA 0014.dat"));

wingspan = 457.2;
root = 228.6;
tip = 152.4;
sweep = 304.8;

wirelength = 544.5;
horizaxislength = 569;
speed = 182;

wingHorizOffset = 53;
wingVertOffset = 0;
wingDepthOffset = 0;

rapidSpeed = 300;

%Flip bottom of array
%Move top of array to bottom
%Flip axis is at the front of the airfoil
[m, minXIndex] = min(rootFoil(:,1));
rootFoil = circshift(rootFoil, ceil(length(rootFoil)/2),1);
tipFoil = circshift(tipFoil, ceil(length(tipFoil)/2),1);

%x coords always need to match when straight cut
%x coords need to be Root:x Tip: 0 + sweep
rootFoil = rootFoil.*root;
tipFoil = tipFoil.*tip;
tipFoil(:,1) = tipFoil(:,1) + sweep;

%Move both foils up
rootFoilMin = abs(min(rootFoil(:,2)));
rootFoil(:,2) = rootFoilMin + rootFoil(:,2);
tipFoil(:,2) = rootFoilMin + tipFoil(:,2);


%Correct the cutting order
output = cat(2,rootFoil, tipFoil);

%Interpolate with wire length
offsetOutput = [[]];
for i = 1:length(output)
   offsetOutput(i,1) = interp1([0 wingspan], output(i,[1,3]), -wingHorizOffset, 'linear', 'extrap');
   offsetOutput(i,2) = interp1([0 wingspan], output(i,[2,4]), -wingHorizOffset, 'linear', 'extrap');
   offsetOutput(i,3) = interp1([0 wingspan], output(i,[1,3]), wirelength-wingHorizOffset, 'linear', 'extrap');
   offsetOutput(i,4) = interp1([0 wingspan], output(i,[2,4]), wirelength-wingHorizOffset, 'linear', 'extrap');
end
testout = offsetOutput;
%Apply x offset to get 0 point correct
offsetOutput(:,1) = offsetOutput(:,1) + wingHorizOffset * tan(atan(sweep/wingspan));
offsetOutput(:,3) = offsetOutput(:,3) + wingHorizOffset * tan(atan(sweep/wingspan));

%Add slight overlap
offsetOutput = cat(1,offsetOutput,offsetOutput(1:3,:));

%Apply depth offset
offsetOutput(:,1) = offsetOutput(:,1) + wingDepthOffset;
offsetOutput(:,3) = offsetOutput(:,3) + wingDepthOffset;

%Move backwards away
offsetOutput = cat(1, offsetOutput, offsetOutput(end,:).*[0 1 0 1]);
%Add feedrate
offsetOutput = [offsetOutput speed.*ones([length(offsetOutput),1])];
%Speed up first move
offsetOuput(1,5) = rapidSpeed;
%File
fileID = fopen('1.txt','w');
fprintf(fileID, 'G1 X%3.3f  Y%3.3f  U%3.3f  Z%3.3f  F%3.3f\n', offsetOutput(1,:));
fprintf(fileID, '%s\n', "M0");
for i = 2:size(offsetOutput,1)
    fprintf(fileID, 'G1 X%3.3f  Y%3.3f  U%3.3f  Z%3.3f  F%3.3f\n', offsetOutput(i,:));
end
fprintf(fileID,'%s',"M5");
fclose(fileID);

hold on
ax1 = plot(offsetOutput(:,1), offsetOutput(:,2));
plot(offsetOutput(:,3), offsetOutput(:,4));
% plot(output(:,3), output(:,4))
% plot(output(:,1), output(:,2))
hold off
max = 500;
axis([0 800 0 50]);