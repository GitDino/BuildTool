# 删除 build 文件
if [[ -d build ]];
then
rm -rf build -r
fi

# 当前目录是否存在IPADir文件，不存则创建
if [ ! -d ./IPA ];
then
mkdir -p IPA;
fi

# 返回上一级目录
cd ..

# 工程绝对路径
project_path=$(cd `dirname $0`; pwd)

echo "Place enter your project name:"

# 读取终端输入并存入 name 变量，并赋值于 project_name 与 scheme_name
read name
project_name=$name
scheme_name=$name

# build文件夹（存放.xcarchive文件）路径
build_path=${project_path}/buildTool/build

echo "Place enter the number you want to export: [ 1:app-store 2:ad-hoc]"

# 读取终端输入并进行逻辑判断
read number
while([[ $number != 1 ]] && [[ $number != 2 ]])
do
echo "Error! Should enter 1 or 2"
echo "Place enter the number you want to export ? [ 1:app-store 2:ad-hoc] "
read number
done

# 根据 number 的值读取 plist 配置文件路径
if [ $number == 1 ];
then
development_mode=Release
exportOptionsPlistPath=${project_path}/buildTool/exportAppstore.plist
echo "Please input your AppStore account number: "
read account_number
echo "Please input your APP-Specific Passwords:"
read specific_pwd
else
development_mode=Debug
exportOptionsPlistPath=${project_path}/buildTool/exportAdHoc.plist
echo "Plaese input firim's API-Token:"
read fir_token
fi

# 获取导出 ipa 包路径
exportIpaPath=${project_path}/buildTool/IPA/${development_mode}

echo ' ++++++++++++++++ '
echo ' + 正在清理工程 + '
echo ' ++++++++++++++++ '
xcodebuild \
clean -configuration ${development_mode} -quiet  || exit

echo ' +++++++++++++ '
echo ' + 清理完成 + '
echo ' +++++++++++++ '

# 编译工程并将 .xcarchive 文件存入 build_path 路径中
echo ' +++++++++++++ '
echo ' 正在编译工程: '${development_mode}
echo ' +++++++++++++ '
xcodebuild \
archive -workspace ${project_path}/${project_name}.xcworkspace \
-scheme ${scheme_name} \
-configuration ${development_mode} \
-archivePath ${build_path}/${project_name}.xcarchive  -quiet  || exit

echo ' +++++++++++++ '
echo ' + 编译完成 + '
echo ' +++++++++++++ '

echo ' ++++++++++++++++ '
echo ' + 开始ipa打包 + '
echo ' ++++++++++++++++ '
xcodebuild -exportArchive -archivePath ${build_path}/${project_name}.xcarchive \
-configuration ${development_mode} \
-exportPath ${exportIpaPath} \
-exportOptionsPlist ${exportOptionsPlistPath} \
-quiet || exit

if [ -e $exportIpaPath/$scheme_name.ipa ]; then
echo ' ++++++++++++++++ '
echo ' + ipa包已导出 + '
echo ' ++++++++++++++++ '
open $exportIpaPath
else
echo ' +++++++++++++++++ '
echo ' + ipa包导出失败 + '
echo ' +++++++++++++++++ '
fi

echo ' +++++++++++++++ '
echo ' + 打包ipa完成 + '
echo ' ++++++++++++++++ '

echo ' +++++++++++++++++ '
echo ' + 开始发布ipa包 + '
echo ' +++++++++++++++++ '

if [ $number == 1 ];
then
# 验证并上传到 AppStore
altoolPath="/Applications/Xcode.app/Contents/Applications/Application Loader.app/Contents/Frameworks/ITunesSoftwareService.framework/Versions/A/Support/altool"
"$altoolPath" --validate-app -f ${exportIpaPath}/${scheme_name}.ipa -u $account_number -p $specific_pwd
"$altoolPath" --upload-app -f ${exportIpaPath}/${scheme_name}.ipa -u  $account_number -p $specific_pwd
else
#上传到Fir
# 将XXX替换成自己的Fir平台的token
fir login -T $fir_token
fir publish $exportIpaPath/$scheme_name.ipa
fi

exit 0
