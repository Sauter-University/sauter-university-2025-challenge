import pandas as pd
from datetime import date
from pathlib import Path
from typing import List

class BasinRepository:
    """Repository that persists and reads basin data in annual files,
    organized by ingestion date."""

    def __init__(self, base_dir: str = "basin_data"):
        self.base_dir = Path(base_dir)

    def _get_path_for_ingestion(self, ingestion_date: date, year: int) -> Path:
        date_folder = ingestion_date.strftime('%Y-%m-%d')
        return self.base_dir / date_folder / f"basin_data_{year}.parquet"

    def save_dataframe_for_ingestion(self, df: pd.DataFrame, year: int, ingestion_date: date):
        file_path = self._get_path_for_ingestion(ingestion_date, year)
        file_path.parent.mkdir(parents=True, exist_ok=True)
        print(f"Saving data for year {year} to '{file_path}'")
        df.to_parquet(file_path, index=False)

    def find_by_date_range(self, start_date: date, end_date: date) -> pd.DataFrame:
        """Busca dados lendo apenas os arquivos Parquet dos anos necessários."""
        all_dfs: List[pd.DataFrame] = []
        for year in range(start_date.year, end_date.year + 1):
            old_path = Path("data") / f"basin_data_{year}.parquet"
            if old_path.exists():
                df = pd.read_parquet(old_path)
                all_dfs.append(df)
        
        if not all_dfs:
            return pd.DataFrame()

        combined_df = pd.concat(all_dfs, ignore_index=True)
        combined_df['ear_data'] = pd.to_datetime(combined_df['ear_data']).dt.date
        mask = (combined_df['ear_data'] >= start_date) & (combined_df['ear_data'] <= end_date)
        sorted_df = combined_df[mask].sort_values(by=['ear_data', 'nom_bacia'], ascending=[True, True])
        
        return sorted_df