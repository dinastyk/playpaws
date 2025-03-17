def calculate_percentage_compatibility(user_min, user_max, breed_min, breed_max):
    # Calculate the overlap of the user's range and the breed's range
    overlap_min = max(user_min, breed_min)
    overlap_max = min(user_max, breed_max)
    
    # If there is no overlap, return 0% compatibility
    if overlap_min >= overlap_max:
        return 0
    
    # Calculate the overlap percentage based on the total range
    overlap_range = overlap_max - overlap_min
    user_range = user_max - user_min
    breed_range = breed_max - breed_min
    
    # Percentage compatibility based on the overlap over the total range of the breed or user
    overlap_percentage = (overlap_range / min(user_range, breed_range)) * 100
    return overlap_percentage

def calculate_height_weight_compatibility(user_min_height, user_max_height, user_min_weight, user_max_weight, breed):
    # Calculate height compatibility percentage
    height_compat = calculate_percentage_compatibility(user_min_height, user_max_height, breed['min_height'], breed['max_height'])
    
    # Calculate weight compatibility percentage
    weight_compat = calculate_percentage_compatibility(user_min_weight, user_max_weight, breed['min_weight'], breed['max_weight'])
    
    return height_compat, weight_compat

# Apply height and weight compatibility calculation to the breed data
breed_data['height_weight_compat'] = breed_data.apply(
    lambda row: calculate_height_weight_compatibility(
        user_preferences['min_height'], user_preferences['max_height'], 
        user_preferences['min_weight'], user_preferences['max_weight'], row
    ), axis=1
)

# Split the height and weight compatibility into two separate columns
breed_data[['height_compat', 'weight_compat']] = pd.DataFrame(breed_data['height_weight_compat'].tolist(), index=breed_data.index)

# Print the breed data with compatibility percentages
print(breed_data[['breed', 'height_compat', 'weight_compat']])