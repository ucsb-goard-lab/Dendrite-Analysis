function  [zoom, microns] = getZoom()
% Extract zoom value from xml file and get the pixel to micron conversion
% for that zoom

% get exact frame number from xml file
xmlname = dir('*.xml'); % select xml file
xml = readstruct(xmlname.name);
zoom = xml.PVStateShard.PVStateValue(17).valueAttribute;

if zoom == 1
    microns = 828;
elseif zoom == 1.5
    microns = 552;
elseif zoom == 1.7
    microns = 487.1;
elseif zoom == 2
    microns = 414;
else
    prompt = strcat(['Please enter micron to pixel equivalent for zoom value ' ...
        'of ',num2str(zoom)]);
    dlgtitle = 'Input';
    dims = [1 35];
    definput = {'20','hsv'};
    microns = inputdlg(prompt,dlgtitle,dims,definput);
end