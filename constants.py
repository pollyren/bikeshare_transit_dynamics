MODAL_COLOURS = {
    'MI-FLM': '#0B5563', 
    'MI-FM': '#118A8F', 
    'MI-LM': '#17BEBB', 
    'MS': '#E4572E', 
    'none': 'lightgrey'
} 

CITY_COLOURS = {
    'Chicago': '#477998', 
    'NYC': '#841C26', 
    'LA': '#87AC5D'
}

CITIES = {
    'Chicago': 'Chicago',
    'NYC': 'New York City',
    'LA': 'Los Angeles'
}

PROVIDER_TO_CITY = {
    'Divvy': 'Chicago',
    'Citi': 'NYC',
    'Metro': 'LA'
}

CITY_TO_PROVIDER_TITLE = {
    'Chicago': 'Divvy + CTA', 
    'NYC': 'Citi Bike + MTA', 
    'LA': 'Metro Bikeshare + Metro'
}

MONTHS = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
]

TIMES = {
    'Early morning (12 AM - 4 AM)': (0, 4),
    'Morning (4 AM - 8 AM)': (4, 8),
    'Late morning (8 AM - 12PM)': (8, 12),
    'Afternoon (12 PM - 4 PM)': (12, 16),
    'Evening (4 PM - 8 PM)': (16, 20),
    'Night (8 PM - 12 AM)': (20, 24),
}

CLASSIFICATIONS = {
    'mi': ['MI-FLM', 'MI-FM', 'MI-LM'],
    'ms': ['MS'],
    'none': ['none']
}