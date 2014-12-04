def instance_status
 `aws rds describe-db-instances --db-instance-identifier district-steam-staging \
                                --query 'DBInstances[0].[DBInstanceStatus][0]'`
end

def wait_for_status status
  until instance_status =~ status
    puts "Waiting..."
    sleep 5
  end
end

def delete_instance
  `aws rds delete-db-instance --db-instance-identifier district-steam-staging \
                              --skip-final-snapshot`
end

def restore_instance
  `aws rds restore-db-instance-to-point-in-time --target-db-instance-identifier district-steam-staging \
                                                --source-db-instance-identifier district-steam \
                                                --db-subnet-group district-steam-public \
                                                --port 3306 \
                                                --use-latest-restorable-time \
                                                --publicly-accessible`
end

def add_security_group
  `aws rds modify-db-instance --db-instance-identifier district-steam-staging \
                              --vpc-security-group-ids sg-30bac855 \
                              --apply-immediately`
end

# Delete the current staging db
puts 'Deleting staging-db...'
delete_instance

# Wait until the deletion is complete
wait_for_status('')

# Create a fresh staging db with the latest backup from production
puts 'Restoring staging-db...'
restore_instance

# Wait until the new db instance is available
wait_for_status('available')

# Add the Database Server security group
puts 'Adding security group...'

# Wait until the new db instance is available
wait_for_status('available')

puts 'Update complete!'
