import pandas as pd
from datetime import date
from pathlib import Path
from typing import List

class ReservoirRepository:
    """Repositório que persiste e lê dados em arquivos anuais."""

    def __init__(self, base_dir: str = "data"):
        self.base_dir = Path(base_dir)
        self.base_dir.mkdir(exist_ok=True)

    def _get_path_for_year(self, year: int) -> Path:
        return self.base_dir / f"reservoir_data_{year}.parquet"

    def save_for_year(self, df: pd.DataFrame, year: int):
        """Salva o DataFrame de um ano específico, substituindo se já existir."""
        file_path = self._get_path_for_year(year)
        df.to_parquet(file_path, index=False)

    def find_by_date_range(self, start_date: date, end_date: date) -> pd.DataFrame:
        """Busca dados lendo apenas os arquivos Parquet dos anos necessários."""
        all_dfs: List[pd.DataFrame] = []
        for year in range(start_date.year, end_date.year + 1):
            file_path = self._get_path_for_year(year)
            if file_path.exists():
                df = pd.read_parquet(file_path)
                all_dfs.append(df)
        
        if not all_dfs:
            return pd.DataFrame()

        combined_df = pd.concat(all_dfs, ignore_index=True)
        combined_df['ear_data'] = pd.to_datetime(combined_df['ear_data']).dt.date
        mask = (combined_df['ear_data'] >= start_date) & (combined_df['ear_data'] <= end_date)
        return combined_df[mask]