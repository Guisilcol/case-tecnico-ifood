import typing
import dataclasses
import sys

import awsglue.utils as glue_utils


@dataclasses.dataclass
class GlueResolvedArgs:
    """
    Classe para resolver argumentos passados para um job AWS Glue.
    Basta herdar desta classe e definir os campos necessários.
    A classe filha precisa ser um dataclass.
    """

    @classmethod
    def get(cls, argv: "list[str]" = sys.argv) -> "tuple[typing.Self, dict[str, str]]":
        """
        Resolve os argumentos passados para o job Glue.
        Retorna uma instância da classe com os valores resolvidos e um dicionário com todos os argumentos resolvidos.
        """
        fields = dataclasses.fields(cls)
        resolved_options = glue_utils.getResolvedOptions(
            argv,
            [f.name for f in fields],
        )
        data = {
            field.name: resolved_options[field.name]
            for field in fields
            if field.name in resolved_options
        }

        return cls(**data), resolved_options
