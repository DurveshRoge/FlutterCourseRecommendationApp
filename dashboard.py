import pandas as pd
import numpy as np
from typing import Dict, Union, Tuple


def getvaluecounts(df: pd.DataFrame) -> Dict[str, int]:
    """Get the distribution of courses by subject."""
    try:
        if 'subject' not in df.columns:
            return {}
        counts = df['subject'].value_counts().head(10)
        return {str(k): int(v) for k, v in counts.items()}
    except Exception as e:
        print(f"Error in getvaluecounts: {e}")
        return {}


def getlevelcount(df: pd.DataFrame) -> Dict[str, int]:
    """Get the distribution of courses by level."""
    try:
        if 'level' not in df.columns or 'num_subscribers' not in df.columns:
            return {}
        level_counts = df.groupby('level')['num_subscribers'].count()
        # Remove 'All Levels' if it exists and get other levels
        if 'All Levels' in level_counts.index:
            level_counts = level_counts.drop('All Levels')
        return {str(k): int(v) for k, v in level_counts.items()}
    except Exception as e:
        print(f"Error in getlevelcount: {e}")
        return {}


def getsubjectsperlevel(df: pd.DataFrame) -> Dict[str, int]:
    """Get the distribution of courses by subject and level."""
    try:
        if 'subject' not in df.columns or 'level' not in df.columns:
            return {}
        # Create a cross-tabulation of subjects and levels
        subject_level_dist = pd.crosstab(df['subject'], df['level'])
        # Convert to dictionary format
        result = {}
        for subject in subject_level_dist.index:
            for level in subject_level_dist.columns:
                key = f"{subject} - {level}"
                value = subject_level_dist.loc[subject, level]
                if value > 0:  # Only include non-zero values
                    result[key] = int(value)
        return result
    except Exception as e:
        print(f"Error in getsubjectsperlevel: {e}")
        return {}


def yearwiseprofit(df: pd.DataFrame) -> Tuple[Dict[str, float], Dict[str, int], Dict[str, float], Dict[str, int]]:
    """Calculate yearly and monthly profit and subscriber metrics."""
    try:
        if not all(col in df.columns for col in ['price', 'num_subscribers', 'published_timestamp']):
            return {}, {}, {}, {}
            
        # Create an explicit copy to avoid the SettingWithCopyWarning
        df = df.copy()
        
        # Clean and convert price data
        df['price'] = df['price'].replace({'FREE': '0', 'True': '0', 'Free': '0'}, regex=True)
        df['price'] = pd.to_numeric(df['price'], errors='coerce').fillna(0)
        df['profit'] = df['price'] * df['num_subscribers']

        # Convert timestamp to datetime
        df['published_date'] = pd.to_datetime(df['published_timestamp'].str.split('T').str[0], 
                                            format="%Y-%m-%d", 
                                            errors='coerce')
        
        # Drop rows with invalid dates
        df = df.dropna(subset=['published_date'])

        # Extract date components
        df['Year'] = df['published_date'].dt.year
        df['Month_name'] = df['published_date'].dt.strftime('%B')

        # Calculate yearly metrics
        yearly_profit = df.groupby('Year')['profit'].sum()
        yearly_subscribers = df.groupby('Year')['num_subscribers'].sum()

        # Calculate monthly metrics
        monthly_profit = df.groupby('Month_name')['profit'].sum()
        monthly_subscribers = df.groupby('Month_name')['num_subscribers'].sum()

        # Convert to dictionaries with proper numeric types
        profitmap = {str(k): float(v) for k, v in yearly_profit.items()}
        subscribersmap = {str(k): int(v) for k, v in yearly_subscribers.items()}
        profitmonthwise = {str(k): float(v) for k, v in monthly_profit.items()}
        monthwisesub = {str(k): int(v) for k, v in monthly_subscribers.items()}

        return profitmap, subscribersmap, profitmonthwise, monthwisesub
    except Exception as e:
        print(f"Error in yearwiseprofit: {e}")
        return {}, {}, {}, {}
