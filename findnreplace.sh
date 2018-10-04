#Author Vikrant Dhimate
#Find and Replace script
numbers=( $(find / -name "crm-model.jar") )
for (( i=0; i<${#numbers[@]}; i++ ));
do
        scp crm-model.jar  ${numbers[i]};
        echo  ${numbers[i]};
done
