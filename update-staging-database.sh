function instance_status {
 aws rds describe-db-instances --db-instance-identifier district-steam-staging \
                               --query 'DBInstances[0].[DBInstanceStatus][0]'
}

function wait_for_instance_status {
STATUS=$(instance_status)
until [[ $(instance_status) =~ $1 ]]
  do
    echo "Waiting for status: $1..."
    sleep 5
  done
}

# Delete the current staging db
# echo 'Deleting staging-db...'
# aws rds delete-db-instance --db-instance-identifier district-steam-staging \
#                            --skip-final-snapshot

# Wait until the new db instance is available
wait_for_instance_status 'not found'

# Create a fresh staging db with the latest backup from production
echo 'Restoring staging-db from latest backup...'
aws rds restore-db-instance-to-point-in-time --target-db-instance-identifier district-steam-staging \
                                             --source-db-instance-identifier district-steam \
                                             --db-subnet-group district-steam-public \
                                             --port 3306 \
                                             --use-latest-restorable-time \
                                             --publicly-accessible

# Wait until the new db instance is available
wait_for_instance_status 'available'

# Add the Database Server security group
echo 'Adding security group...'
aws rds modify-db-instance --db-instance-identifier district-steam-staging \
                           --vpc-security-group-ids sg-30bac855 \
                           --apply-immediately

wait_for_instance_status 'available'
echo 'All done!'
